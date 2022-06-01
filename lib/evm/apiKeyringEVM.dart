import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:bip39/bip39.dart' as bip39;
import 'package:ethers/signers/wallet.dart' as ethers;
import 'package:polkawallet_sdk/api/types/addressIconData.dart';
import 'package:polkawallet_sdk/service/index.dart';
import 'package:polkawallet_sdk/storage/keyringEVM.dart';
import 'package:polkawallet_sdk/storage/types/ethWalletData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:web3dart/web3dart.dart';

enum EVMKeyType { mnemonic, privateKey, keystore }

/// KeyringEVM API manages EVM keyPairs
class ApiKeyringEVM {
  ApiKeyringEVM(this.service);

  final SubstrateService? service;

  /// Generate a set of new mnemonic.
  Future<AddressIconDataWithMnemonic> generateMnemonic(
      {String derivePath = '', String key = ''}) async {
    final mnemonic = bip39.generateMnemonic();
    final wallet = ethers.Wallet.fromMnemonic(mnemonic);
    return AddressIconDataWithMnemonic.fromJson({
      'mnemonic': mnemonic,
      'address': wallet.address,
      'svg': 'xxx',
    });
  }

  /// get address and avatar from mnemonic.
  Future<AddressIconData> addressFromMnemonic(String mnemonic,
      {String derivePath = ''}) async {
    final wallet = ethers.Wallet.fromMnemonic(mnemonic);
    return AddressIconData.fromJson({'address': wallet.address, 'svg': 'xxx'});
  }

  /// get address and avatar from privateKey.
  Future<AddressIconData> addressFromRawSeed(String privateKey,
      {String derivePath = ''}) async {
    final wallet = ethers.Wallet.fromPrivateKey(privateKey);
    return AddressIconData.fromJson({'address': wallet.address, 'svg': 'xxx'});
  }

  // /// get address and avatar from KeyStore.
  // Future<AddressIconData> addressFromKeyStore(Map keyStore) async {
  //   final wallet = Wallet.fromJson(
  //     jsonEncode(keyStore),
  //   );
  //   return AddressIconData.fromJson({'address': wallet.address, 'svg': 'xxx'});
  // }

  /// check mnemonic valid.
  Future<bool> checkMnemonicValid(String mnemonic) async {
    return bip39.validateMnemonic(mnemonic);
  }

  /// Import account from mnemonic/rawSeed/keystore and we get a JSON object.
  /// param [cryptoType] can be `sr25519`(default) or `ed25519`.
  /// throw error if import failed.
  /// return null if keystore password check failed.
  Future<Map<String, dynamic>> importAccount(
    KeyringEVM keyring, {
    required EVMKeyType keyType,
    required String key,
    required String name,
    required String password,
    String derivePath = '',
  }) async {
    Wallet web3Wallet;
    switch (keyType) {
      case EVMKeyType.mnemonic:
        final wallet = ethers.Wallet.fromMnemonic(key);
        final credential = EthPrivateKey.fromHex(wallet.privateKey!);
        web3Wallet = Wallet.createNew(credential, password, Random.secure());
        break;
      case EVMKeyType.privateKey:
        final credential = EthPrivateKey.fromHex(key);
        web3Wallet = Wallet.createNew(credential, password, Random.secure());
        break;
      case EVMKeyType.keystore:
        web3Wallet = Wallet.fromJson(key, password);
    }
    final walletJson = jsonDecode(web3Wallet.toJson());
    final type = keyType.toString().split('.')[1];
    return {
      ...walletJson,
      'address': web3Wallet.privateKey.address.hex,
      'name': name,
      type: key,
    };
  }

  /// Add account to local storage.
  Future<EthWalletData> addAccount(
    KeyringEVM keyring, {
    required EVMKeyType keyType,
    required Map<String, dynamic> acc,
    required String password,
  }) async {
    // save seed and remove it before add account
    final type = keyType.toString().split('.')[1];
    if (keyType == EVMKeyType.mnemonic || keyType == EVMKeyType.privateKey) {
      final String? seed = acc[type];
      if (seed != null && seed.isNotEmpty) {
        keyring.store
            .encryptSeedAndSave(acc['address'], acc[type], type, password);
      }
    }
    acc.remove(type);

    // save keystore to storage
    await keyring.store.addAccount(acc);

    await updateIconsMap(keyring, [acc['address']]);

    return EthWalletData.fromJson(acc);
  }

  /// Add a contact.
  Future<EthWalletData> addContact(KeyringEVM keyring, Map acc) async {
    // save keystore to storage
    await keyring.store.addContact(acc);

    await updateIconsMap(keyring, [acc['address']]);

    return keyring.contacts.firstWhere((e) => e.address == acc['address']);
  }

  /// This method query account icons and set icons to [KeyringEVM.store]
  /// so we can get icon of an account from [KeyringEVM] instance.
  Future<void> updateIconsMap(KeyringEVM keyring, [List? addresses]) async {
    // final List<String?> ls = [];
    // if (addresses != null) {
    //   ls.addAll(List<String>.from(addresses));
    // } else {
    //   ls.addAll(keyring.keyPairs.map((e) => e.address).toList());
    //   ls.addAll(keyring.contacts.map((e) => e.address).toList());
    // }
    //
    // if (ls.length == 0) return;
    // // get icons from webView.
    // final res = await service!.getPubKeyIconsMap(ls);
    // // set new icons to Keyring instance.
    // if (res != null) {
    //   final data = {};
    //   res.forEach((e) {
    //     data[e[0]] = e[1];
    //   });
    //   keyring.store.updateIconsMap(Map<String, String>.from(data));
    // }
  }

  /// Decrypt and get the backup of seed.
  Future<bool> checkEncryptedSeedExist(
      KeyringEVM keyring, EthWalletData acc, EVMKeyType keyType) async {
    return keyring.store.checkSeedExist(keyType, acc.address ?? '');
  }

  /// Decrypt and get the backup of seed.
  Future<SeedBackupData?> getDecryptedSeed(
      KeyringEVM keyring, EthWalletData acc, password) async {
    final Map? data =
        await keyring.store.getDecryptedSeed(acc.address, password);
    if (data == null) {
      return null;
    }
    if (data['seed'] == null) {
      data['error'] = 'wrong password';
    }
    return SeedBackupData.fromJson(data as Map<String, dynamic>);
  }

  /// delete account from storage
  Future<void> deleteAccount(KeyringEVM keyring, EthWalletData account) async {
    if (account != null) {
      await keyring.store.deleteAccount(account.address);
    }
  }

  /// check password of account
  Future<bool> checkPassword(EthWalletData account, String pass) async {
    try {
      Wallet.fromJson(jsonEncode(account.toJson()), pass);
      return true;
    } catch (err) {
      print(err.toString());
      // ignore
    }
    return false;
  }

  /// change password of account
  Future<EthWalletData?> changePassword(
      KeyringEVM keyring, String passOld, passNew) async {
    final acc = keyring.current;
    // 1. check old password
    final res = await checkPassword(acc, passOld);
    if (!res) {
      return null;
    }
    final wallet = Wallet.fromJson(jsonEncode(acc.toJson()), passOld);
    final walletNew =
        Wallet.createNew(wallet.privateKey, passNew, Random.secure());

    final walletJson = jsonDecode(walletNew.toJson());
    final accNew = EthWalletData()
      ..address = acc.address
      ..name = acc.name
      ..memo = acc.memo
      ..observation = acc.observation
      ..id = walletJson['id']
      ..version = walletJson['version']
      ..crypto = walletJson['crypto'];

    // 2. then update encrypted seed in local storage.
    keyring.store.updateEncryptedSeed(acc.address, passOld, passNew);

    // 3. update keyPair data in storage
    keyring.store.updateAccount(accNew.toJson());
    return accNew;
  }

  /// change name of account
  Future<KeyPairData> changeName(KeyringEVM keyring, String name) async {
    final json = keyring.current.toJson();
    json['name'] = name;
    // update keyPair date in storage
    keyring.store.updateAccount(json);
    return KeyPairData.fromJson(json);
  }

  // /// Open a new webView for a DApp,
  // /// sign extrinsic or msg for the DApp.
  // Future<ExtensionSignResult?> signAsExtension(
  //     String password, SignAsExtensionParam param) async {
  //   final signature = await service!.signAsExtension(password, param.toJson());
  //   if (signature == null) {
  //     return null;
  //   }
  //   final ExtensionSignResult res = ExtensionSignResult();
  //   res.id = param.id;
  //   res.signature = signature['signature'];
  //   return res;
  // }
  //
  // Future<VerifyResult?> signatureVerify(
  //     String message, signature, address) async {
  //   final res = await service!.signatureVerify(message, signature, address);
  //   if (res == null) {
  //     return null;
  //   }
  //   return VerifyResult.fromJson(
  //       Map<String, dynamic>.of(res as Map<String, dynamic>));
  // }
}

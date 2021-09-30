import 'package:polkawallet_sdk/eth/keyring.dart';
import 'package:polkawallet_sdk/storage/keyringETH.dart';
import 'package:polkawallet_sdk/storage/types/GenerateMnemonicData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairETHData.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';

import 'api.dart';

enum ETH_KeyType { mnemonic, privateKey, keystore }

class ApiETHKeyring {
  ApiETHKeyring(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ETHServiceKeyring? service;

  /// Generate a set of new mnemonic.
  Future<GenerateMnemonicData> generateMnemonic(
      {int? index, String? mnemonic}) async {
    final mnemonicData = await service!
        .generateMnemonic(index: index ?? 0, mnemonic: mnemonic ?? "");
    return mnemonicData;
  }

  /// get address and avatar from mnemonic.
  Future<GenerateMnemonicData> addressFromMnemonic(
      {required String derivePath, required String mnemonic}) async {
    final acc = await service!
        .addressFromMnemonic(derivePath: derivePath, mnemonic: mnemonic);
    if (acc['error'] != null) {
      throw Exception(acc['error']);
    }
    return GenerateMnemonicData.fromJson(acc);
  }

  /// get address and avatar from privateKey.privateKey: string
  Future<dynamic> addressFromPrivateKey({required String privateKey}) async {
    final acc = await service!.addressFromPrivateKey(privateKey: privateKey);
    if (acc['error'] != null) {
      throw Exception(acc['error']);
    }
    return GenerateMnemonicData.fromJson(acc);
  }

  Future<Map?> importAccount({
    required ETH_KeyType keyType,
    required String key,
    required String derivePath,
    required String name,
    required String password,
  }) async {
    final dynamic acc = await service!.importAccount(
        keyType: keyType,
        key: key,
        derivePath: derivePath,
        password: password,
        name: name);
    if (acc == null) {
      return null;
    }
    if (acc['error'] != null) {
      throw Exception(acc['error']);
    }

    return acc;
  }

  /// check password of account
  Future<bool> checkPassword(
      {required String keystore, required String pass}) async {
    final res = await service!.checkPassword(keystore: keystore, pass: pass);
    return res;
  }

  /// change password of account
  Future<KeyPairETHData?> changePassword(
      {required KeyringETH keyring,
      required String passOld,
      required String passNew}) async {
    // 1. change password of keyPair in webView
    final res = await service!.changePassword(
        keystore: keyring.current.keystore!,
        passNew: passNew,
        passOld: passOld);
    if (res == null) {
      return null;
    }

    if (res['error'] != null) {
      throw Exception(res['error']);
    }

    res['name'] = keyring.current.name;

    // 2. if success in webView, then update encrypted seed in local storage.
    keyring.store.updateEncryptedSeed(
        address: keyring.current.address!, passOld: passOld, passNew: passNew);

    // update keyPair date in storage
    keyring.store.updateAccount(res as Map<String, dynamic>);
    return KeyPairETHData.fromJson(res);
  }

  /// get signer of a signature. so we can verify the signer.
  Future<dynamic> verifySignature(
      {required String message, required String signature}) async {
    final res =
        await service!.verifySignature(message: message, signature: signature);

    if (res['error'] != null) {
      throw Exception(res['error']);
    }
    return res;
  }

  /// Add account to local storage.
  Future<KeyPairETHData> addAccount(
    KeyringETH keyring, {
    required ETH_KeyType keyType,
    required Map acc,
    required String password,
  }) async {
    // save seed and remove it before add account
    if (keyType == ETH_KeyType.mnemonic || keyType == ETH_KeyType.privateKey) {
      final String type = keyType.toString().split('.')[1];
      final String? seed = acc[type];
      if (seed != null && seed.isNotEmpty) {
        //acc['pubKey'], acc[type], type, password
        keyring.store.encryptSeedAndSave(
            address: acc['address'],
            seed: acc[type],
            seedType: type,
            password: password);
        acc.remove(type);
      }
    }

    // save keystore to storage
    await keyring.store.addAccount(acc);

    await updatePubKeyIconsMap(keyring, [acc['address']]);
    // updatePubKeyAddressMap(keyring);
    // updateIndicesMap(keyring, [acc['address']]);

    return KeyPairETHData.fromJson(acc as Map<String, dynamic>);
  }

  /// This method query account icons and set icons to [Keyring.store]
  /// so we can get icon of an account from [Keyring] instance.
  Future<void> updatePubKeyIconsMap(KeyringETH keyring, [List? address]) async {
    final List<String?> ls = [];
    if (address != null) {
      ls.addAll(List<String>.from(address));
    } else {
      ls.addAll(keyring.keyPairs.map((e) => e.address).toList());
      ls.addAll(keyring.contacts.map((e) => e.address).toList());
    }

    if (ls.length == 0) return;
    // get icons from webView.
    final res = await service!.getPubKeyIconsMap(ls);
    // set new icons to Keyring instance.
    if (res != null) {
      final data = {};
      res.forEach((e) {
        data[e[0]] = e[1];
      });
      keyring.store.updateIconsMap(Map<String, String>.from(data));
    }
  }

  /// change name of account
  Future<KeyPairETHData> changeName(KeyringETH keyring, String name) async {
    final json = keyring.current.toJson();
    // update json meta data
    service!.updateKeyPairMetaData(json, name);
    // update keyPair date in storage
    keyring.store.updateAccount(json);
    return KeyPairETHData.fromJson(json);
  }

  /// delete account from storage
  Future<void> deleteAccount(KeyringETH keyring, KeyPairETHData account) async {
    await keyring.store.deleteAccount(account.address);
  }

  /// Open a new webView for a DApp,
  /// sign extrinsic or msg for the DApp.
  Future<ExtensionSignResult?> signMessage(
    String password,
    String message,
    String keystore,
  ) async {
    final signature = await service!
        .signMessage(keystore: keystore, message: message, pass: password);
    if (signature == null) {
      return null;
    }
    final ExtensionSignResult res = ExtensionSignResult();
    res.signature = signature['signature'];
    return res;
  }

  Future<dynamic> signatureVerify(String message, signature) async {
    final res =
        await service!.verifySignature(message: message, signature: signature);
    if (res == null) {
      return null;
    }
    return res;
  }

  /// Decrypt and get the backup of seed.
  Future<SeedBackupData?> getDecryptedSeed(KeyringETH keyring, password) async {
    final Map? data = await keyring.store.getDecryptedSeed(
        address: keyring.current.address!, password: password);
    if (data == null) {
      return null;
    }
    if (data['seed'] == null) {
      data['error'] = 'wrong password';
    }
    return SeedBackupData.fromJson(data as Map<String, dynamic>);
  }

  /// Add a contact.
  Future<KeyPairData> addContact(KeyringETH keyring, Map acc) async {
    // save keystore to storage
    await keyring.store.addContact(acc);

    await updatePubKeyIconsMap(keyring, [acc['address']]);
    // updateIndicesMap(keyring, [acc['address']]);

    return keyring.contacts.firstWhere((e) => e.address == acc['address']);
  }
}

import 'dart:convert';

import 'package:polkawallet_sdk/api/types/addressIconData.dart';
import 'package:polkawallet_sdk/ethers/apiEthers.dart';
import 'package:polkawallet_sdk/service/eth/keyringEth.dart';
import 'package:polkawallet_sdk/storage/keyringEVM.dart';
import 'package:polkawallet_sdk/storage/types/ethWalletData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';

import '../api.dart';

class ApiKeyringEth {
  ApiKeyringEth(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceKeyringEth service;

  /// Generate a set of new mnemonic.
  Future<AddressIconDataWithMnemonic> generateMnemonic(
      {int? index, String? mnemonic}) async {
    final mnemonicData = await service.generateMnemonic(
        index: index ?? 0, mnemonic: mnemonic ?? "");
    return mnemonicData;
  }

  /// get address and avatar from mnemonic.
  Future<AddressIconData> addressFromMnemonic(
      {required String derivePath, required String mnemonic}) async {
    final acc = await service.addressFromMnemonic(
        derivePath: derivePath, mnemonic: mnemonic);
    if (acc['error'] != null) {
      throw Exception(acc['error']);
    }
    return AddressIconData.fromJson(acc);
  }

  /// get address and avatar from privateKey.privateKey: string
  Future<AddressIconData> addressFromPrivateKey(
      {required String privateKey}) async {
    final acc = await service.addressFromPrivateKey(privateKey: privateKey);
    if (acc['error'] != null) {
      throw Exception(acc['error']);
    }
    return AddressIconData.fromJson(acc);
  }

  Future<Map?> importAccount({
    required EVMKeyType keyType,
    required String key,
    required String name,
    required String password,
  }) async {
    final acc = await service.importAccount(
        keyType: keyType, key: key, password: password, name: name);

    if (acc['error'] != null) {
      throw Exception(acc['error']);
    }

    return acc;
  }

  /// check password of account
  Future<bool> checkPassword(EthWalletData account, String pass) async {
    final res = await service.checkPassword(
        keystore: jsonEncode(account.toJson()), pass: pass);
    return res;
  }

  /// change password of account
  Future<EthWalletData?> changePassword(
      KeyringEVM keyring, String passOld, String passNew) async {
    // 1. change password of keyPair in webView
    final res = await service.changePassword(
        keystore: jsonEncode(keyring.current.toJson()),
        passNew: passNew,
        passOld: passOld);

    if (res['error'] != null) {
      throw Exception(res['error']);
    }

    res['name'] = keyring.current.name;

    // 2. if success in webView, then update encrypted seed in local storage.
    keyring.store
        .updateEncryptedSeed(keyring.current.address!, passOld, passNew);

    // update keyPair data in storage
    keyring.store.updateAccount(res);
    return EthWalletData.fromJson(res);
  }

  /// Add account to local storage.
  Future<EthWalletData> addAccount(
    KeyringEVM keyring, {
    required EVMKeyType keyType,
    required Map acc,
    required String password,
  }) async {
    // save seed and remove it before add account
    final String type = keyType.toString().split('.')[1];
    if (keyType == EVMKeyType.mnemonic || keyType == EVMKeyType.privateKey) {
      final String? seed = acc[type];
      if (seed != null && seed.isNotEmpty) {
        //acc['pubKey'], acc[type], type, password
        keyring.store
            .encryptSeedAndSave(acc['address'], acc[type], type, password);
      }
    }
    acc.remove(type);

    // save keystore to storage
    await keyring.store.addAccount(acc);

    await updateAddressIconsMap(keyring, [acc['address']]);

    return EthWalletData.fromJson(acc);
  }

  /// This method query account icons and set icons to [Keyring.store]
  /// so we can get icon of an account from [Keyring] instance.
  Future<void> updateAddressIconsMap(KeyringEVM keyring,
      [List? address]) async {
    final List<String?> ls = [];
    if (address != null) {
      ls.addAll(List<String>.from(address));
    } else {
      ls.addAll(keyring.keyPairs.map((e) => e.address).toList());
      ls.addAll(keyring.contacts.map((e) => e.address).toList());
    }

    if (ls.length == 0) return;
    // get icons from webView.
    final res = await service.getAddressIcons(ls);
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
  Future<EthWalletData> changeName(KeyringEVM keyring, String name) async {
    final json = keyring.current.toJson();
    // update keyPair date in storage
    keyring.store.updateAccount(json);
    return EthWalletData.fromJson(json);
  }

  /// delete account from storage
  Future<void> deleteAccount(KeyringEVM keyring, EthWalletData account) async {
    await keyring.store.deleteAccount(account.address);
  }

  /// Open a new webView for a DApp,
  /// sign extrinsic or msg for the DApp.
  Future<ExtensionSignResult?> signMessage(
    String password,
    String message,
    EthWalletData account,
  ) async {
    final signature = await service.signMessage(
        keystore: jsonEncode(account.toJson()),
        message: message,
        pass: password);
    if (signature == null) {
      return null;
    }
    if (signature['error'] != null) {
      throw Exception(signature['error']);
    }
    final ExtensionSignResult res = ExtensionSignResult();
    res.signature = signature['signature'];
    return res;
  }

  /// get signer of a signature. so we can verify the signer.
  Future<Map> signatureVerify(String message, String signature) async {
    final res =
        await service.verifySignature(message: message, signature: signature);
    if (res['error'] != null) {
      throw Exception(res['error']);
    }
    return res;
  }

  /// Decrypt and get the backup of seed.
  Future<SeedBackupData?> getDecryptedSeed(KeyringEVM keyring, password) async {
    final Map? data = await keyring.store
        .getDecryptedSeed(keyring.current.address!, password);
    if (data == null) {
      return null;
    }
    if (data['seed'] == null) {
      data['error'] = 'wrong password';
    }
    return SeedBackupData.fromJson(data as Map<String, dynamic>);
  }

  /// Add a contact.
  Future<EthWalletData> addContact(KeyringEVM keyring, Map acc) async {
    // save keystore to storage
    await keyring.store.addContact(acc);

    await updateAddressIconsMap(keyring, [acc['address']]);

    return EthWalletData.fromJson(acc);
  }
}

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:polkawallet_sdk/service/keyring.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';

enum KeyType { mnemonic, rawSeed, keystore }
enum CryptoType { sr25519, ed25519 }

class ApiKeyring {
  ApiKeyring(this.service);

  final ServiceKeyring service;

  /// Generate a set of new mnemonic.
  Future<String> generateMnemonic() async {
    final mnemonic = await service.generateMnemonic();
    return mnemonic;
  }

  /// Import account from mnemonic/rawSeed/keystore.
  /// param [cryptoType] can be `sr25519`(default) or `ed25519`.
  /// return [null] if import failed.
  Future<KeyPairData> importAccount(
    Keyring keyring, {
    @required KeyType keyType,
    @required String key,
    @required String name,
    @required String password,
    CryptoType cryptoType = CryptoType.sr25519,
    String derivePath = '',
  }) async {
    final Map acc = await service.importAccount(
      keyType: keyType,
      key: key,
      name: name,
      password: password,
      cryptoType: cryptoType,
      derivePath: derivePath,
    );

    // save seed and remove it before add account
    if (keyType == KeyType.mnemonic || keyType == KeyType.rawSeed) {
      final String type = keyType.toString().split('.')[1];
      final String seed = acc[type];
      if (seed != null && seed.isNotEmpty) {
        keyring.store
            .encryptSeedAndSave(acc['pubKey'], acc[type], type, password);
        acc.remove(type);
      }
    }

    // save keystore to storage
    await keyring.store.addAccount(acc);

    updatePubKeyAddressMap(keyring);

    return KeyPairData.fromJson(acc);
  }

  /// Every time we change the keyPairs, we need to update the
  /// pubKey-address map.
  Future<void> updatePubKeyAddressMap(Keyring keyring) async {
    // get new addresses from webView.
    final res = await service.updatePubKeyAddressMap(
        keyring.store.list, keyring.store.ss58List);

    // set new addresses to Keyring instance.
    if (res != null && res[keyring.ss58.toString()] != null) {
      keyring.store.updatePubKeyAddressMap(Map<String, Map>.from(res));
    }
  }

  /// Decrypt and get the backup of seed.
  Future<SeedBackupData> getDecryptedSeed(
      Keyring keyring, KeyPairData acc, password) async {
    final Map data = await keyring.store.getDecryptedSeed(acc.pubKey, password);
    if (data == null) {
      return null;
    }
    if (data['seed'] == null) {
      data['error'] = 'wrong password';
    }
    return SeedBackupData.fromJson(data);
  }

  /// delete account from storage
  Future<void> deleteAccount(Keyring keyring, KeyPairData account) async {
    if (account != null) {
      await keyring.store.deleteAccount(account.pubKey);
    }
  }

  /// check password of account
  Future<bool> checkPassword(KeyPairData account, String pass) async {
    final res = await service.checkPassword(account.pubKey, pass);
    return res;
  }

  /// change password of account
  Future<KeyPairData> changePassword(
    Keyring keyring,
    KeyPairData acc,
    String passOld,
    passNew,
  ) async {
    // 1. change password of keyPair in webView
    final res = await service.changePassword(acc.pubKey, passOld, passNew);
    if (res == null) {
      return null;
    }
    // 2. if success in webView, then update encrypted seed in local storage.
    keyring.store.updateEncryptedSeed(acc.pubKey, passOld, passNew);

    // update json meta data
    service.updateKeyPairMetaData(res, acc.name);
    // update keyPair date in storage
    keyring.store.updateAccount(res);
    return KeyPairData.fromJson(res);
  }

  /// change name of account
  Future<KeyPairData> changeName(
      Keyring keyring, KeyPairData acc, String name) async {
    final json = acc.toJson();
    // update json meta data
    service.updateKeyPairMetaData(json, name);
    // update keyPair date in storage
    keyring.store.updateAccount(json);
    return KeyPairData.fromJson(json);
  }

  /// Check if derive path is valid, return [null] if valid,
  /// and return error message if invalid.
  Future<String> checkDerivePath(
      String seed, path, CryptoType cryptoType) async {
    String res = await service.checkDerivePath(seed, path, cryptoType);
    return res;
  }

  /// Open a new webView for a DApp, and interact with the DApp.
  Future<ExtensionSignResult> signBytesAsExtension(
      String password, SignBytesParam param) async {
    final signature = await service.signAsExtension(
        password, SignBytesRequest.toJson(param.request));
    if (signature == null) {
      return null;
    }
    final ExtensionSignResult res = ExtensionSignResult();
    res.id = param.id;
    res.signature = signature['signature'];
    return res;
  }

  /// Open a new webView for a DApp,
  /// sign extrinsic for the DApp.
  Future<ExtensionSignResult> signExtrinsicAsExtension(
      String password, SignExtrinsicParam param) async {
    final signature = await service.signAsExtension(
        password, SignExtrinsicRequest.toJson(param.request));
    if (signature == null) {
      return null;
    }
    final ExtensionSignResult res = ExtensionSignResult();
    res.id = param.id;
    res.signature = signature['signature'];
    return res;
  }
}

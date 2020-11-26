import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/service/keyring.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';

enum KeyType { mnemonic, rawSeed, keystore }
enum CryptoType { sr25519, ed25519 }

class ApiKeyring {
  ApiKeyring(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceKeyring service;

  /// Generate a set of new mnemonic.
  Future<String> generateMnemonic() async {
    final mnemonic = await service.generateMnemonic();
    return mnemonic;
  }

  /// Import account from mnemonic/rawSeed/keystore.
  /// param [cryptoType] can be `sr25519`(default) or `ed25519`.
  /// throw error if import failed.
  /// return null if keystore password check failed.
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
    if (acc == null) {
      return null;
    }
    if (acc['error'] != null) {
      throw Exception(acc['error']);
    }

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
    updatePubKeyIconsMap(keyring, [acc['pubKey']]);
    updateIndicesMap(keyring, [acc['address']]);

    return KeyPairData.fromJson(acc);
  }

  /// Add a contact.
  Future<KeyPairData> addContact(Keyring keyring, Map acc) async {
    final pubKey =
        await service.serviceRoot.account.decodeAddress([acc['address']]);
    acc['pubKey'] = pubKey.keys.toList()[0];

    // save keystore to storage
    await keyring.store.addContact(acc);

    await updatePubKeyAddressMap(keyring);
    await updatePubKeyIconsMap(keyring, [acc['pubKey']]);
    updateIndicesMap(keyring, [acc['address']]);

    return KeyPairData.fromJson(Map<String, dynamic>.from(acc));
  }

  /// Every time we change the keyPairs, we need to update the
  /// pubKey-address map.
  Future<void> updatePubKeyAddressMap(Keyring keyring) async {
    final ls = keyring.store.list.toList();
    ls.addAll(keyring.store.contacts);
    // get new addresses from webView.
    final res = await service.getPubKeyAddressMap(ls, keyring.store.ss58List);

    // set new addresses to Keyring instance.
    if (res != null && res[keyring.ss58.toString()] != null) {
      keyring.store.updatePubKeyAddressMap(Map<String, Map>.from(res));
    }
  }

  Future<void> updatePubKeyIconsMap(Keyring keyring, [List pubKeys]) async {
    final ls = List<String>();
    if (pubKeys != null) {
      ls.addAll(List<String>.from(pubKeys));
    } else {
      ls.addAll(keyring.keyPairs.map((e) => e.pubKey).toList());
      ls.addAll(keyring.contacts.map((e) => e.pubKey).toList());
    }

    if (ls.length == 0) return;
    // get icons from webView.
    final res = await service.getPubKeyIconsMap(ls);
    // set new icons to Keyring instance.
    if (res != null) {
      final data = {};
      res.forEach((e) {
        data[e[0]] = e[1];
      });
      keyring.store.updateIconsMap(Map<String, String>.from(data));
    }
  }

  Future<void> updateIndicesMap(Keyring keyring, [List addresses]) async {
    final ls = List<String>();
    if (addresses != null) {
      ls.addAll(List<String>.from(addresses));
    } else {
      ls.addAll(keyring.allWithContacts.map((e) => e.address).toList());
    }

    if (ls.length == 0) return;
    // get account indices from webView.
    final res = await apiRoot.account.queryIndexInfo(ls);
    // set new indices to Keyring instance.
    if (res != null) {
      final data = {};
      res.forEach((e) {
        data[e['accountId']] = e;
      });
      keyring.store.updateIndicesMap(Map<String, Map>.from(data));
    }
  }

  /// Decrypt and get the backup of seed.
  Future<SeedBackupData> getDecryptedSeed(Keyring keyring, password) async {
    final Map data =
        await keyring.store.getDecryptedSeed(keyring.current.pubKey, password);
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
      Keyring keyring, String passOld, passNew) async {
    final acc = keyring.current;
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
  Future<KeyPairData> changeName(Keyring keyring, String name) async {
    final json = keyring.current.toJson();
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
      String password, SignAsExtensionParam param) async {
    final signature = await service.signAsExtension(password, param.request);
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
      String password, SignAsExtensionParam param) async {
    final signature = await service.signAsExtension(password, param.request);
    if (signature == null) {
      return null;
    }
    final ExtensionSignResult res = ExtensionSignResult();
    res.id = param.id;
    res.signature = signature['signature'];
    return res;
  }
}

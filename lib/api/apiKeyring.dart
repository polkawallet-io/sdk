import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:polkawallet_sdk/api/types/keyPairData.dart';
import 'package:polkawallet_sdk/service/keyring.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';

enum KeyType { mnemonic, rawSeed, keystore }
enum CryptoType { sr25519, ed25519 }

class ApiKeyring {
  ApiKeyring(this.service);

  final ServiceKeyring service;

  List<KeyPairData> get list {
    return service.list.map((e) => KeyPairData.fromJson(e)).toList();
  }

  /// Decrypt and get the backup of seed.
  Future<SeedBackupData> getDecryptedSeed(KeyPairData acc, password) async {
    final Map data = await service.getDecryptedSeed(acc.pubKey, password);
    if (data == null) {
      return null;
    }
    if (data['seed'] == null) {
      data['error'] = 'wrong password';
    }
    return SeedBackupData.fromJson(data);
  }

//  Future<void> initAccounts() async {
//    if (apiRoot.storage.keyPairs.val.length > 0) {
//      String accounts = jsonEncode(apiRoot.storage.keyPairs.val);
//
//      String ss58 = jsonEncode(network_ss58_map.values.toSet().toList());
//      Map keys =
//          await apiRoot.evalJavascript('account.initKeys($accounts, $ss58)');
//      store.account.setPubKeyAddressMap(Map<String, Map>.from(keys));
//
//      // get accounts icons
//      getPubKeyIcons(store.account.accountList.map((i) => i.pubKey).toList());
//    }
//
//    // and contacts icons
//    List<AccountData> contacts =
//        List<AccountData>.of(store.settings.contactList);
//    getAddressIcons(contacts.map((i) => i.address).toList());
//    // set pubKeyAddressMap for observation accounts
//    contacts.retainWhere((i) => i.observation);
//    List<String> observations = contacts.map((i) => i.pubKey).toList();
//    if (observations.length > 0) {
//      encodeAddress(observations);
//      getPubKeyIcons(observations);
//    }
//  }

//  Future<void> changeCurrentAccount({
//    String pubKey,
//    bool fetchData = false,
//  }) async {
//    String current = pubKey;
//    if (pubKey == null) {
//      if (store.account.accountListAll.length > 0) {
//        current = store.account.accountListAll[0].pubKey;
//      } else {
//        current = '';
//      }
//    }
//    store.account.setCurrentAccount(current);
//
//    // refresh balance
//    store.assets.clearTxs();
//    store.assets.loadAccountCache();
//    if (fetchData) {
//      webApi.assets.fetchBalance();
//    }
//    if (store.settings.endpoint.info == networkEndpointAcala.info) {
//      store.acala.setTransferTxs([], reset: true);
//      store.acala.loadCache();
//    } else {
//      // refresh user's staking info if network is kusama or polkadot
//      store.staking.clearState();
//      store.staking.loadAccountCache();
//      if (fetchData) {
//        webApi.staking.fetchAccountStaking();
//      }
//    }
//  }
//

  /// Generate a set of new mnemonic.
  Future<String> generateMnemonic() async {
    final mnemonic = await service.generateMnemonic();
    return mnemonic;
  }

  /// Import account from mnemonic/rawSeed/keystore.
  /// param [cryptoType] can be `sr25519`(default) or `ed25519`.
  /// return [null] if import failed.
  Future<KeyPairData> importAccount({
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
    return KeyPairData.fromJson(acc);
  }

  /// delete account from storage
  Future<void> deleteAccount(KeyPairData account) async {
    if (account != null) {
      await service.deleteAccount(account.pubKey);
    }
  }

  /// check password of account
  Future<bool> checkPassword(KeyPairData account, String pass) async {
    final res = await service.checkPassword(account.pubKey, pass);
    return res;
  }

  /// change password of account
  Future<KeyPairData> changePassword(
      KeyPairData acc, String passOld, passNew) async {
    // change password of keyPair in webView
    final res = await service.changePassword(acc.pubKey, passOld, passNew);
    if (res == null) {
      return null;
    }
    // update json meta data
    service.updateKeyPairMetaData(res, acc.name);
    // update keyPair date in storage
    service.updateAccount(res);
    return KeyPairData.fromJson(res);
  }

  /// change name of account
  Future<KeyPairData> changeName(KeyPairData acc, String name) async {
    final json = KeyPairData.toJson(acc);
    // update json meta data
    service.updateKeyPairMetaData(json, name);
    // update keyPair date in storage
    service.updateAccount(json);
    return KeyPairData.fromJson(json);
  }

  /// Check if derive path is valid, return [null] if valid,
  /// and return error message if invalid.
  Future<String> checkDerivePath(
      String seed, path, CryptoType cryptoType) async {
    String res = await service.checkDerivePath(seed, path, cryptoType);
    return res;
  }

//  Future<Map> parseQrCode(String data) async {
//    final res = await apiRoot.evalJavascript('account.parseQrCode("$data")');
//    print('rawData: $data');
//    return res;
//  }
//
//  Future<Map> signAsync(String password) async {
//    final res = await apiRoot.evalJavascript('account.signAsync("$password")');
//    return res;
//  }
//
//  Future<Map> makeQrCode(Map txInfo, List params, {String rawParam}) async {
//    String param = rawParam != null ? rawParam : jsonEncode(params);
//    final Map res = await apiRoot.evalJavascript(
//      'account.makeTx(${jsonEncode(txInfo)}, $param)',
//      allowRepeat: true,
//    );
//    return res;
//  }
//
//  Future<Map> addSignatureAndSend(
//    String signed,
//    Map txInfo,
//    String pageTile,
//    String notificationTitle,
//  ) async {
//    final String address = store.account.currentAddress;
//    final Map res = await apiRoot.evalJavascript(
//      'account.addSignatureAndSend("$address", "$signed")',
//      allowRepeat: true,
//    );
//
//    if (res['hash'] != null) {
//      String hash = res['hash'];
//      NotificationPlugin.showNotification(
//        int.parse(hash.substring(0, 6)),
//        notificationTitle,
//        '$pageTile - ${txInfo['module']}.${txInfo['call']}',
//      );
//    }
//    return res;
//  }

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

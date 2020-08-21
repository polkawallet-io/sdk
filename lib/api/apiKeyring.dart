import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:polkawallet_sdk/api/types/accountData.dart';
import 'package:polkawallet_sdk/service/keyring.dart';

enum KeyType { mnemonic, rawSeed, keystore }
enum CryptoType { sr25519, ed25519 }

class ApiKeyring {
  ApiKeyring(this.service);

  final ServiceKeyring service;

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

//  /// encode addresses to publicKeys
//  Future<void> encodeAddress(List<String> pubKeys) async {
//    Map res = await service.encodeAddress(pubKeys, [ss58]);
//    if (res != null) {
//      store.account.setPubKeyAddressMap(Map<String, Map>.from(res));
//    }
//  }

  /// decode addresses to publicKeys
  Future<Map> decodeAddress(List<String> addresses) async {
    Map res = await service.decodeAddress(addresses);
    return res;
  }

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
  Future<AccountData> importAccount({
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
    return AccountData.fromJson(acc);
  }

  /// check password of account
  Future<bool> checkAccountPassword(AccountData account, String pass) async {
    final res = await service.checkAccountPassword(account.pubKey, pass);
    return res;
  }

  /// Check if derive path is valid, return [null] if valid,
  /// and return error message if invalid.
  Future<String> checkDerivePath(String seed, path, pairType) async {
    String res = await service.checkDerivePath(seed, path, pairType);
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
//
//  Future<Map> signAsExtension(String password, Map args) async {
//    final String call = args['msgType'] == WalletExtensionSignPage.signTypeBytes
//        ? 'signBytesAsExtension'
//        : 'signTxAsExtension';
//    final res = await apiRoot.evalJavascript(
//      'account.$call("$password", ${jsonEncode(args['request'])})',
//      allowRepeat: true,
//    );
//    return res;
//  }
}

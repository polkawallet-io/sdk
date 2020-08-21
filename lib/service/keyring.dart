import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/service/index.dart';

class ServiceKeyring {
  ServiceKeyring(this.serviceRoot);

  final SubstrateService serviceRoot;

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

  /// encode addresses to publicKeys
  Future<Map> encodeAddress(List<String> pubKeys, ss58List) async {
    Map res = await serviceRoot.evalJavascript(
      'account.encodeAddress(${jsonEncode(pubKeys)}, ${jsonEncode(ss58List)})',
      allowRepeat: true,
    );
    return res;
  }

  /// decode addresses to publicKeys
  Future<Map> decodeAddress(List<String> addresses) async {
    Map res = await serviceRoot
        .evalJavascript('account.decodeAddress(${jsonEncode(addresses)})');
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
    final Map<String, dynamic> acc = await serviceRoot.evalJavascript(
      'account.gen()',
      allowRepeat: true,
    );
    return acc['mnemonic'];
  }

  /// Import account from mnemonic/rawSeed/keystore.
  /// param [cryptoType] can be `sr25519`(default) or `ed25519`.
  /// return [null] if import failed.
  Future<Map> importAccount({
    @required KeyType keyType,
    @required String key,
    @required name,
    @required password,
    CryptoType cryptoType = CryptoType.sr25519,
    String derivePath = '',
  }) async {
    // generate json from js-api
    final String type = keyType.toString().split('.')[1];
    final String crypto = cryptoType.toString().split('.')[1];
    String code =
        'account.recover("$type", "$crypto", \'$key$derivePath\', "$password")';
    code = code.replaceAll(RegExp(r'\t|\n|\r'), '');
    final Map<String, dynamic> acc = await serviceRoot.evalJavascript(
      code,
      allowRepeat: true,
    );
    if (acc == null || acc['error'] != null) {
      return null;
    }

    // add metadata to json
    acc['name'] = name;
    acc['meta']['name'] = name;
    if (acc['meta']['whenCreated'] == null) {
      acc['meta']['whenCreated'] = DateTime.now().millisecondsSinceEpoch;
    }
    acc['meta']['whenEdited'] = DateTime.now().millisecondsSinceEpoch;

    // save keystore to storage
    serviceRoot.storage.keyPairs.val.add(acc);

    // save encrypted key to storage
    if (keyType == KeyType.mnemonic || keyType == KeyType.rawSeed) {
//      apiRoot.storage.keyPairs.val.add(acc);
    }

    return acc;
  }

  /// check password of account
  Future<bool> checkAccountPassword(String pubKey, pass) async {
    final res = await serviceRoot.evalJavascript(
      'account.checkPassword("$pubKey", "$pass")',
      allowRepeat: true,
    );
    if (res == null) {
      return false;
    }
    return true;
  }

  Future<String> checkDerivePath(String seed, path, pairType) async {
    String res = await serviceRoot.evalJavascript(
      'account.checkDerivePath("$seed", "$path", "$pairType")',
      allowRepeat: true,
    );
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

}

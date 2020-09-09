import 'dart:async';
import 'dart:convert';

import 'package:polkawallet_sdk/service/index.dart';

class ServiceAccount {
  ServiceAccount(this.serviceRoot);

  final SubstrateService serviceRoot;

  /// encode addresses to publicKeys
  Future<Map> encodeAddress(List<String> pubKeys, ss58List) async {
    Map res = await serviceRoot.evalJavascript(
        'account.encodeAddress(${jsonEncode(pubKeys)}, ${jsonEncode(ss58List)})');
    return res;
  }

  /// decode addresses to publicKeys
  Future<Map> decodeAddress(List<String> addresses) async {
    Map res = await serviceRoot
        .evalJavascript('account.decodeAddress(${jsonEncode(addresses)})');
    return res;
  }

  /// query staking info of a list of pubKeys
  Future<List> queryBonded(List<String> pubKeys) async {
    List res = await serviceRoot.evalJavascript(
        'account.queryAccountsBonded(api, ${jsonEncode(pubKeys)})');
    return res;
  }

//  Future<dynamic> _testSendTx() async {
//    Completer c = new Completer();
//    void onComplete(res) {
//      c.complete(res);
//    }
//
//    Timer(Duration(seconds: 6), () => onComplete({'hash': '0x79867'}));
//    return c.future;
//  }

//  Future<dynamic> sendTx(
//      Map txInfo, List params, String pageTile, String notificationTitle,
//      {String rawParam}) async {
//    String param = rawParam != null ? rawParam : jsonEncode(params);
//    String call = 'account.sendTx(${jsonEncode(txInfo)}, $param)';
////    print(call);
//    Map res = await apiRoot.evalJavascript(call, allowRepeat: true);
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

  /// Get on-chain account info of addresses
  Future<List> queryIndexInfo(List addresses) async {
    var res = await serviceRoot.evalJavascript(
        'account.getAccountIndex(api, ${jsonEncode(addresses)})');
    return res;
  }

  Future<List> getPubKeyIcons(List<String> keys) async {
    List res = await serviceRoot
        .evalJavascript('account.genPubKeyIcons(${jsonEncode(keys)})');
    return res;
  }

  Future<List> getAddressIcons(List<String> addresses) async {
    List res = await serviceRoot
        .evalJavascript('account.genIcons(${jsonEncode(addresses)})');
    return res;
  }

//  Future<Map> queryRecoverable(String address) async {
////    address = "J4sW13h2HNerfxTzPGpLT66B3HVvuU32S6upxwSeFJQnAzg";
//    Map res = await apiRoot
//        .evalJavascript('api.query.recovery.recoverable("$address")');
//    if (res != null) {
//      res['address'] = address;
//    }
//    store.account.setAccountRecoveryInfo(res);
//
//    if (res != null && List.of(res['friends']).length > 0) {
//      getAddressIcons(res['friends']);
//    }
//    return res;
//  }
//
//  Future<List> queryRecoverableList(List<String> addresses) async {
//    List queries =
//        addresses.map((e) => 'api.query.recovery.recoverable("$e")').toList();
//    final List ls = await apiRoot.evalJavascript(
//      'Promise.all([${queries.join(',')}])',
//      allowRepeat: true,
//    );
//
//    List res = [];
//    ls.asMap().forEach((k, v) {
//      if (v != null) {
//        v['address'] = addresses[k];
//      }
//      res.add(v);
//    });
//
//    return res;
//  }
//
//  Future<List> queryActiveRecoveryAttempts(
//      String address, List<String> addressNew) async {
//    List queries = addressNew
//        .map((e) => 'api.query.recovery.activeRecoveries("$address", "$e")')
//        .toList();
//    final res = await apiRoot.evalJavascript(
//      'Promise.all([${queries.join(',')}])',
//      allowRepeat: true,
//    );
//    return res;
//  }
//
//  Future<List> queryActiveRecoveries(
//      List<String> addresses, String addressNew) async {
//    List queries = addresses
//        .map((e) => 'api.query.recovery.activeRecoveries("$e", "$addressNew")')
//        .toList();
//    final res = await apiRoot.evalJavascript(
//      'Promise.all([${queries.join(',')}])',
//      allowRepeat: true,
//    );
//    return res;
//  }
//
//  Future<List> queryRecoveryProxies(List<String> addresses) async {
//    List queries =
//        addresses.map((e) => 'api.query.recovery.proxy("$e")').toList();
//    final res = await apiRoot.evalJavascript(
//      'Promise.all([${queries.join(',')}])',
//      allowRepeat: true,
//    );
//    return res;
//  }
}

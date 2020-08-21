import 'dart:async';

import 'package:polkawallet_sdk/service/account.dart';

class ApiAccount {
  ApiAccount(this.service);

  final ServiceAccount service;

//  Future<void> fetchAccountsBonded(List<String> pubKeys) async {
//    if (pubKeys.length > 0) {
//      List res = await apiRoot.evalJavascript(
//          'account.queryAccountsBonded(${jsonEncode(pubKeys)})');
//      store.account.setAccountsBonded(res);
//    }
//  }
//
//  Future<Map> estimateTxFees(Map txInfo, List params, {String rawParam}) async {
//    String param = rawParam != null ? rawParam : jsonEncode(params);
//    print(txInfo);
//    Map res = await apiRoot.evalJavascript(
//        'account.txFeeEstimate(${jsonEncode(txInfo)}, $param)',
//        allowRepeat: true);
//    return res;
//  }
//
//  Future<dynamic> _testSendTx() async {
//    Completer c = new Completer();
//    void onComplete(res) {
//      c.complete(res);
//    }
//
//    Timer(Duration(seconds: 6), () => onComplete({'hash': '0x79867'}));
//    return c.future;
//  }
//
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
  Future<List> getAccountsIndex(List addresses) async {
    if (addresses == null || addresses.length == 0) {
      return [];
    }

    var res = await service.getAccountsIndex(addresses);
    return res;
  }

  /// Get icons of pubKeys
  /// return svg strings
  Future<List> getPubKeyIcons(List keys) async {
    if (keys == null || keys.length == 0) {
      return [];
    }
    List res = await service.getPubKeyIcons(keys);
    return res;
  }

  /// Get icons of addresses
  /// return svg strings
  Future<List> getAddressIcons(List addresses) async {
    if (addresses == null || addresses.length == 0) {
      return [];
    }
    List res = await service.getAddressIcons(addresses);
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

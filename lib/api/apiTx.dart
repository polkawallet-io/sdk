import 'dart:async';
import 'dart:convert';

import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/service/tx.dart';

class ApiTx {
  ApiTx(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceTx service;

  /// Estimate tx fees, [params] will be ignored if we have [rawParam].
  Future<TxFeeEstimateResult> estimateTxFees(TxInfoData txInfo, List params,
      {String rawParam}) async {
    final String param = rawParam != null ? rawParam : jsonEncode(params);
    final Map tx = TxInfoData.toJson(txInfo);
    final res = await service.estimateTxFees(tx, param);
    return TxFeeEstimateResult.fromJson(res);
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

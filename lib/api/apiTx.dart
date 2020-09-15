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
    print(tx);
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

  /// Send tx, [params] will be ignored if we have [rawParam].
  /// [onStatusChange] is a callback when tx status change.
  /// @return txHash [string] if tx finalized success.
  Future<String> sendTx(
    TxInfoData txInfo,
    List params,
    String password, {
    Function(String) onStatusChange,
    String rawParam,
  }) async {
    final param = rawParam != null ? rawParam : jsonEncode(params);
    final Map tx = TxInfoData.toJson(txInfo);
    tx['address'] = txInfo.keyPair.address;
    tx['pubKey'] = txInfo.keyPair.pubKey;
    final res = await service.sendTx(
      tx,
      param,
      password,
      onStatusChange ?? (status) => print(status),
    );
    if (res['error']) {
      throw Exception(res['error']);
    }
    return res['hash'];
  }

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

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
  Future<TxFeeEstimateResult> estimateFees(TxInfoData txInfo, List params,
      {String? rawParam, String? jsApi}) async {
    final String param = rawParam != null ? rawParam : jsonEncode(params);
    final Map tx = txInfo.toJson();
    final res = await (service.estimateFees(tx, param, jsApi: jsApi));
    return TxFeeEstimateResult.fromJson(res as Map<String, dynamic>);
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
  Future<Map> signAndSend(
    TxInfoData txInfo,
    List params,
    String password, {
    Function(String)? onStatusChange,
    String? rawParam,
  }) async {
    final param = rawParam != null ? rawParam : jsonEncode(params);
    final Map tx = txInfo.toJson();
    print(tx);
    print(param);
    final res = await service.signAndSend(
      tx,
      param,
      password,
      onStatusChange ?? (status) => print(status),
    );
    if (res?['error'] != null) {
      throw Exception(res?['error']);
    }
    return res ?? {};
  }
}

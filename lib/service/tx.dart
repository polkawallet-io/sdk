import 'dart:async';
import 'dart:convert';

import 'package:polkawallet_sdk/service/index.dart';

class ServiceTx {
  ServiceTx(this.serviceRoot);

  final SubstrateService serviceRoot;

  Future<Map> estimateTxFees(Map txInfo, String params) async {
    Map res = await serviceRoot.evalJavascript(
      'keyring.txFeeEstimate(api, ${jsonEncode(txInfo)}, $params)',
    );
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

  Future<Map> sendTx(Map txInfo, String params, password,
      Function(String) onStatusChange) async {
    final msgId = "onStatusChange${serviceRoot.getEvalJavascriptUID()}";
    serviceRoot.addMsgHandler(msgId, onStatusChange);

    final Map res = await serviceRoot.evalJavascript(
        'account.sendTx(api, ${jsonEncode(txInfo)}, $params, "$password", "$msgId")');
    serviceRoot.removeMsgHandler(msgId);

    return res;
  }
}

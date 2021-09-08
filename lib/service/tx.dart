import 'dart:async';
import 'dart:convert';

import 'package:polkawallet_sdk/service/index.dart';

class ServiceTx {
  ServiceTx(this.serviceRoot);

  final SubstrateService serviceRoot;

  Future<Map?> estimateFees(Map txInfo, String params) async {
    dynamic res = await (serviceRoot.webView!.evalJavascript(
      'keyring.txFeeEstimate(api, ${jsonEncode(txInfo)}, $params)',
    ) as FutureOr<dynamic>);
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

  Future<Map?> signAndSend(Map txInfo, String params, password,
      Function(String) onStatusChange) async {
    final msgId =
        "onStatusChange${serviceRoot.webView!.getEvalJavascriptUID()}";
    serviceRoot.webView!.addMsgHandler(msgId, onStatusChange);
    final code =
        'keyring.sendTx(api, ${jsonEncode(txInfo)}, $params, "$password", "$msgId")';
    // print(code);
    final Map? res =
        await (serviceRoot.webView!.evalJavascript(code) as FutureOr<dynamic>);
    serviceRoot.webView!.removeMsgHandler(msgId);

    return res;
  }
}

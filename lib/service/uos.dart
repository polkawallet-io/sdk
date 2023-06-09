import 'dart:async';
import 'dart:convert';

import 'package:polkawallet_sdk/service/index.dart';

/// Support offline-signature as a hot-wallet:
/// 1. makeQrCode
/// 2. addSignatureAndSend: send tx with address of step1 & signature of step2.
class ServiceUOS {
  ServiceUOS(this.serviceRoot);

  final SubstrateService serviceRoot;

  Future<Map?> addSignatureAndSend(
    String address,
    signed,
    Function(String) onStatusChange,
  ) async {
    final msgId =
        "onStatusChange${serviceRoot.webView!.getEvalJavascriptUID()}";
    serviceRoot.webView!.addMsgHandler(msgId, onStatusChange);

    final dynamic res = await serviceRoot.webView!.evalJavascript(
        'keyring.addSignatureAndSend(api, "$address", "$signed")');
    serviceRoot.webView!.removeMsgHandler(msgId);

    return res;
  }

  Future<Map?> makeQrCode(Map txInfo, List params,
      {String? rawParam, int? ss58}) async {
    String param = rawParam != null ? rawParam : jsonEncode(params);
    final dynamic res = await serviceRoot.webView!.evalJavascript(
      'keyring.makeTx(api, ${jsonEncode(txInfo)}, $param, $ss58)',
    );
    return res;
  }
}

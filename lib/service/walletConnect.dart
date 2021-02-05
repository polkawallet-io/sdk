import 'dart:convert';

import 'package:polkawallet_sdk/service/index.dart';

class ServiceWalletConnect {
  ServiceWalletConnect(this.serviceRoot);

  final SubstrateService serviceRoot;

  Future<Map> connect(
      String uri, Function(Map) onPairing, Function(Map) onPayload) async {
    serviceRoot.webView.addMsgHandler("walletConnectPayload", onPayload);
    serviceRoot.webView.addMsgHandler("walletConnectPairing", onPairing);

    return await serviceRoot.webView
        .evalJavascript('walletConnect.connect("$uri")');
  }

  Future<Map> disconnect(Map params) async {
    final Map res = await serviceRoot.webView
        .evalJavascript('walletConnect.disconnect(${jsonEncode(params)})');
    serviceRoot.webView.removeMsgHandler("walletConnectPayload");
    serviceRoot.webView.removeMsgHandler("walletConnectPairing");
    return res;
  }

  Future<Map> approvePairing(Map proposal, String address) async {
    final Map res = await serviceRoot.webView.evalJavascript(
        'walletConnect.approveProposal(${jsonEncode(proposal)}, "$address")');
    return res;
  }

  Future<Map> rejectPairing(Map proposal) async {
    final Map res = await serviceRoot.webView.evalJavascript(
        'walletConnect.rejectProposal(${jsonEncode(proposal)})');
    return res;
  }

  Future<Map> payloadRespond(Map response) async {
    final Map res = await serviceRoot.webView.evalJavascript(
        'walletConnect.payloadRespond(${jsonEncode(response)})');
    return res;
  }
}

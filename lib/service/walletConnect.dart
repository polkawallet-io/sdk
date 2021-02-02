import 'dart:convert';

import 'package:polkawallet_sdk/service/index.dart';

class ServiceWalletConnect {
  ServiceWalletConnect(this.serviceRoot);

  final SubstrateService serviceRoot;

  Future<Map> connect(String uri, Function(Map) onPayload) async {
    final Map res = await serviceRoot.webView
        .evalJavascript('walletConnect.connect("$uri")');
    serviceRoot.webView.addMsgHandler("walletConnectPayload", onPayload);
    return res;
  }

  Future<Map> disconnect(Map params) async {
    final Map res = await serviceRoot.webView
        .evalJavascript('walletConnect.disconnect(${jsonEncode(params)})');
    serviceRoot.webView.removeMsgHandler("walletConnectPayload");
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

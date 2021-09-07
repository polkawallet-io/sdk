import 'dart:async';
import 'dart:convert';

import 'package:polkawallet_sdk/service/index.dart';

class ServiceWalletConnect {
  ServiceWalletConnect(this.serviceRoot);

  final SubstrateService serviceRoot;

  void initClient(Function(Map) onPairing, Function(Map) onPaired,
      Function(Map) onPayload) {
    serviceRoot.webView!.addMsgHandler("walletConnectPayload", onPayload);
    serviceRoot.webView!.addMsgHandler("walletConnectPairing", onPairing);
    serviceRoot.webView!.addMsgHandler("walletConnectCreated", onPaired);
    serviceRoot.webView!.evalJavascript('walletConnect.initClient()');
  }

  Future<Map?> connect(String uri) async {
    return await (serviceRoot.webView!
            .evalJavascript('walletConnect.connect("$uri")')
        as FutureOr<Map<dynamic, dynamic>?>);
  }

  Future<Map?> disconnect(Map params) async {
    final Map? res = await (serviceRoot.webView!
            .evalJavascript('walletConnect.disconnect(${jsonEncode(params)})')
        as FutureOr<Map<dynamic, dynamic>?>);
    serviceRoot.webView!.removeMsgHandler("walletConnectPayload");
    serviceRoot.webView!.removeMsgHandler("walletConnectPairing");
    serviceRoot.webView!.removeMsgHandler("walletConnectCreated");
    return res;
  }

  Future<Map?> approvePairing(Map proposal, String address) async {
    final Map? res = await (serviceRoot.webView!.evalJavascript(
            'walletConnect.approveProposal(${jsonEncode(proposal)}, "$address")')
        as FutureOr<Map<dynamic, dynamic>?>);
    return res;
  }

  Future<Map?> rejectPairing(Map proposal) async {
    final Map? res = await (serviceRoot.webView!.evalJavascript(
            'walletConnect.rejectProposal(${jsonEncode(proposal)})')
        as FutureOr<Map<dynamic, dynamic>?>);
    return res;
  }

  Future<Map?> signPayload(Map payload, String password) async {
    final Map? res = await (serviceRoot.webView!.evalJavascript(
            'walletConnect.signPayload(api, ${jsonEncode(payload)}, "$password")')
        as FutureOr<Map<dynamic, dynamic>?>);
    return res;
  }

  Future<Map?> payloadRespond(Map response) async {
    final Map? res = await (serviceRoot.webView!.evalJavascript(
            'walletConnect.payloadRespond(${jsonEncode(response)})')
        as FutureOr<Map<dynamic, dynamic>?>);
    return res;
  }
}

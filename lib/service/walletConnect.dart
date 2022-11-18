import 'dart:async';

import 'package:polkawallet_sdk/service/index.dart';

class ServiceWalletConnect {
  ServiceWalletConnect(this.serviceRoot);

  final SubstrateService serviceRoot;

  void initClient(
    String uri,
    String address, {
    required Function(Map) onPairing,
    required Function() onPaired,
    required Function(Map) onCallRequest,
    required Function() onDisconnect,
  }) {
    serviceRoot.webView!
        .evalJavascript('walletConnect.initConnect("$uri", "$address")');
    serviceRoot.webView!.addMsgHandler("wallet_connect_message", (data) {
      final event = data['event'];
      switch (event) {
        case 'session_request':
          onPairing(data['peerMeta']);
          break;
        case 'connect':
          onPaired();
          break;
        case 'call_request':
          onCallRequest(data);
          break;
        case 'disconnect':
          onDisconnect();
          break;
      }
    });
  }

  Future<void> disconnect() async {
    await serviceRoot.webView!.evalJavascript('walletConnect.disconnect()');
    serviceRoot.webView!.removeMsgHandler("wallet_connect_message");
  }

  Future<void> confirmPairing(bool approve) async {
    await serviceRoot.webView!
        .evalJavascript('walletConnect.confirmConnect($approve)');
  }

  Future<Map> confirmPayload(int id, bool approve, String password) async {
    final Map? res = await serviceRoot.webView!.evalJavascript(
        'walletConnect.confirmCallRequest($id, $approve, "$password")');
    return res ?? {};
  }
}

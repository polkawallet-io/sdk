import 'dart:async';
import 'dart:convert';

import 'package:polkawallet_sdk/service/index.dart';

class ServiceWalletConnect {
  ServiceWalletConnect(this.serviceRoot);

  final SubstrateService serviceRoot;

  void initClient(
    String uri,
    String address,
    int chainId, {
    Map? cachedSession,
  }) {
    if (cachedSession != null) {
      serviceRoot.webView!.evalJavascript(
          'walletConnect.reConnectSession(${jsonEncode(cachedSession)})');
    } else {
      serviceRoot.webView!.evalJavascript(
          'walletConnect.initConnect("$uri", "$address", $chainId)');
    }
  }

  void subscribeEvents({
    required Function(Map) onPairing,
    required Function(Map) onPaired,
    required Function(Map) onCallRequest,
    required Function(String) onDisconnect,
    String? uri,
    bool isV2 = false,
  }) {
    serviceRoot.webView!
        .addMsgHandler("wallet_connect_message${isV2 ? '_v2' : ''}", (data) {
      final event = data['event'];
      switch (event) {
        case 'session_request':
        case 'session_proposal':
          onPairing(data);
          break;
        case 'connect':
          onPaired(data['session']);
          break;
        case 'call_request':
          onCallRequest(data);
          break;
        case 'disconnect':
          onDisconnect(uri == null ? data['topic'] : uri);
          break;
      }
    });
  }

  Future<void> disconnect() async {
    await serviceRoot.webView!.evalJavascript('walletConnect.disconnect()');
  }

  Future<void> confirmPairing(bool approve) async {
    await serviceRoot.webView!
        .evalJavascript('walletConnect.confirmConnect($approve)');
  }

  Future<void> confirmPairingV2(bool approve, String address) async {
    await serviceRoot.webView!
        .evalJavascript('walletConnect.confirmConnectV2($approve, "$address")');
  }

  Future<Map> confirmPayload(
      int id, bool approve, String password, Map gasOptions) async {
    final Map? res = await serviceRoot.webView!.evalJavascript(
        'walletConnect.confirmCallRequest($id, $approve, "$password", ${jsonEncode(gasOptions)})');
    return res ?? {};
  }

  Future<Map> confirmPayloadV2(
      int id, bool approve, String password, Map gasOptions) async {
    final Map? res = await serviceRoot.webView!.evalJavascript(
        'walletConnect.confirmCallRequestV2($id, $approve, "$password", ${jsonEncode(gasOptions)})');
    return res ?? {};
  }

  Future<void> changeAccount(String address) async {
    await serviceRoot.webView!
        .evalJavascript('walletConnect.updateSession({address: "$address"})');
  }

  Future<Map> changeAccountV2(String address) async {
    final Map res = await serviceRoot.webView!
        .evalJavascript('walletConnect.updateSessionV2({address: "$address"})');
    return res;
  }

  Future<void> changeNetwork(String chainId, String address) async {
    await serviceRoot.webView!.evalJavascript(
        'walletConnect.updateSession({address: "$address", chainId: $chainId})');
  }

  Future<Map> changeNetworkV2(String chainId, String address) async {
    final Map res = await serviceRoot.webView!.evalJavascript(
        'walletConnect.updateSessionV2({address: "$address", chainId: "$chainId"})');
    return res;
  }

  Future<void> injectCacheDataV2(Map cache, String address) async {
    await serviceRoot.webView!.evalJavascript(
        'walletConnect.injectCacheDataV2(${jsonEncode(cache)}, "$address")');
  }

  Future<void> deletePairingV2(String topic) async {
    await serviceRoot.webView!
        .evalJavascript('walletConnect.deletePairingV2("$topic")');
  }

  Future<void> disconnectV2(String topic) async {
    await serviceRoot.webView!
        .evalJavascript('walletConnect.disconnectV2("$topic")');
  }
}

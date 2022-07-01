import 'dart:async';
import 'dart:convert';

import 'package:polkawallet_sdk/service/index.dart';

class ServiceBridge {
  ServiceBridge(this.serviceRoot);

  final SubstrateService serviceRoot;

  Future<List<String>> getFromChainsAll() async {
    final res =
        await serviceRoot.webView!.evalJavascript('bridge.getFromChainsAll()');
    return List<String>.from(res);
  }

  Future<List<Map>> getRoutes() async {
    final res = await serviceRoot.webView!.evalJavascript('bridge.getRoutes()');
    return List<Map>.from(res);
  }

  Future<Map> getChainsInfo() async {
    final Map res =
        await serviceRoot.webView!.evalJavascript('bridge.getChainsInfo()');
    return res;
  }

  Future<List<String>> connectFromChains(List<String> chains,
      {Map<String, List<String>>? nodeList}) async {
    final res = await serviceRoot.webView!.evalJavascript(
        'bridge.connectFromChains(${jsonEncode(chains)}, ${nodeList == null ? 'undefined' : jsonEncode(nodeList)})');
    return List<String>.from(res);
  }

  Future<void> disconnectFromChains() async {
    serviceRoot.webView!.evalJavascript('bridge.disconnectFromChains()');
  }

  Future<Map> getNetworkProperties(String chain) async {
    final Map res = await serviceRoot.webView!
        .evalJavascript('bridge.getNetworkProperties("$chain")');
    return res;
  }

  Future<void> subscribeBalances(
      String chain, String address, Function(Map) callback) async {
    final msgChannel = '${chain}BridgeTokenBalances$address';
    final code =
        'bridge.subscribeBalances("$chain", "$address", "$msgChannel")';
    serviceRoot.webView!.subscribeMessage(code, msgChannel, callback);
  }

  Future<void> unsubscribeBalances(String chain, String address) async {
    serviceRoot.webView!
        .unsubscribeMessage('${chain}BridgeTokenBalances$address');
  }

  Future<Map> getAmountInputConfig(
      String from, String to, String token, String address) async {
    final Map res = await serviceRoot.webView!.evalJavascript(
        'bridge.getInputConfig("$from", "$to", "$token", "$address")');
    return res;
  }

  Future<Map> getTxParams(String from, String to, String token, String address,
      String amount, int decimals) async {
    final Map res = await serviceRoot.webView!.evalJavascript(
        'bridge.getTxParams("$from", "$to", "$token", "$address", "$amount", $decimals)');
    return res;
  }
}

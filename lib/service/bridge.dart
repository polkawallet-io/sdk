import 'dart:async';
import 'dart:convert';

import 'package:polkawallet_sdk/service/bridgeRunner.dart';
import 'package:polkawallet_sdk/service/index.dart';

class ServiceBridge {
  ServiceBridge(this.serviceRoot);

  final SubstrateService serviceRoot;

  BridgeRunner? _runner;

  ///For multiple use at the same time
  int _retainCount = 0;

  Future<void> init({String? jsCode}) async {
    final c = Completer();
    if (_runner == null) {
      _runner = BridgeRunner();
      await _runner?.launch(() {
        if (!c.isCompleted) c.complete();
      }, jsCode: jsCode);
    } else {
      await _runner?.reload();
      if (!c.isCompleted) c.complete();
    }
    _retainCount++;
    return c.future;
  }

  Future<void> dispose() async {
    _retainCount--;
    if (_retainCount > 0) return;
    _runner?.dispose();
    _runner = null;
  }

  Future<List<String>> getFromChainsAll() async {
    assert(_runner != null, 'bridge not init');
    final res = await _runner?.evalJavascript('bridge.getFromChainsAll()');
    return List<String>.from(res);
  }

  Future<List<Map>> getRoutes() async {
    assert(_runner != null, 'bridge not init');
    final res = await _runner?.evalJavascript('bridge.getRoutes()');
    return List<Map>.from(res);
  }

  Future<Map> getChainsInfo() async {
    assert(_runner != null, 'bridge not init');
    final Map res = await _runner?.evalJavascript('bridge.getChainsInfo()');
    return res;
  }

  Future<String?> _checkConnection(String chain) async {
    final api = await _runner?.evalJavascript(
            'Promise.all([bridge.getApi("$chain")&&bridge.getApi("$chain").isConnected])')
        as List;
    return api[0] == true ? chain : null;
  }

  Future<List<String>> connectFromChains(List<String> chains,
      {Map<String, List<String>>? nodeList}) async {
    assert(_runner != null, 'bridge not init');
    final list =
        await Future.wait(chains.map((e) => _checkConnection(e)).toList());
    final nonNullList =
        list.where((element) => element != null).toList() as List<String>;
    chains.removeWhere((element) => nonNullList.contains(element));
    if (chains.isEmpty) {
      return nonNullList;
    }
    final res = await _runner?.evalJavascript(
        'bridge.connectFromChains(${jsonEncode(chains)}, ${nodeList == null ? 'undefined' : jsonEncode(nodeList)})');
    return List<String>.from(res) + nonNullList;
  }

  Future<void> disconnectFromChains() async {
    assert(_runner != null, 'bridge not init');
    if (_retainCount > 0) return;
    await _runner?.evalJavascript('bridge.disconnectFromChains()');
  }

  Future<Map> getNetworkProperties(String chain) async {
    assert(_runner != null, 'bridge not init');
    final Map res =
        await _runner?.evalJavascript('bridge.getNetworkProperties("$chain")');
    return res;
  }

  Future<void> subscribeBalances(
      String chain, String address, Function(Map) callback) async {
    assert(_runner != null, 'bridge not init');
    final msgChannel = '${chain}BridgeTokenBalances$address';
    final code =
        'bridge.subscribeBalances("$chain", "$address", "$msgChannel")';
    _runner?.subscribeMessage(code, msgChannel, callback);
  }

  Future<void> unsubscribeBalances(String chain, String address) async {
    assert(_runner != null, 'bridge not init');
    _runner?.unsubscribeMessage('${chain}BridgeTokenBalances$address');
  }

  Future<Map> getAmountInputConfig(String from, String to, String token,
      String address, String signer) async {
    assert(_runner != null, 'bridge not init');
    final Map res = await _runner?.evalJavascript(
        'bridge.getInputConfig("$from", "$to", "$token", "$address", "$signer")');
    return res;
  }

  Future<Map> getTxParams(String from, String to, String token, String address,
      String amount, int decimals, String signer) async {
    assert(_runner != null, 'bridge not init');
    final Map res = await _runner?.evalJavascript(
        'bridge.getTxParams("$from", "$to", "$token", "$address", "$amount", $decimals, "$signer")');
    return res;
  }

  Future<String> estimateTxFee(
      String chainFrom, String txHex, String sender) async {
    assert(_runner != null, 'bridge not init');
    final String res = await _runner?.evalJavascript(
        'bridge.estimateTxFee("$chainFrom", "$txHex", "$sender")');
    return res;
  }

  Future<Map?> sendTx(String chainFrom, Map txInfo, String password,
      String msgId, Map keyring) async {
    assert(_runner != null, 'bridge not init');
    final String pairs = jsonEncode(keyring);
    final dynamic res = await _runner?.evalJavascript(
        'bridge.sendTx("$chainFrom", ${jsonEncode(txInfo)},"$password","$msgId",$pairs)');
    if (res?['error'] != null) {
      throw Exception(res?['error']);
    }
    return res;
  }

  void subscribeReloadAction(String reloadKey, Function reloadAction) {
    _runner?.subscribeReloadAction(reloadKey, reloadAction);
  }

  void unsubscribeReloadAction(String reloadKey) {
    _runner?.unsubscribeReloadAction(reloadKey);
  }

  int getEvalJavascriptUID() {
    return _runner?.getEvalJavascriptUID() ?? 0;
  }

  void addMsgHandler(String channel, Function onMessage) {
    _runner?.addMsgHandler(channel, onMessage);
  }

  void removeMsgHandler(String channel) {
    _runner?.removeMsgHandler(channel);
  }

  Future<bool> checkPassword(Map keyring, String? pubKey, pass) async {
    final String pairs = jsonEncode(keyring);
    final res = await _runner
        ?.evalJavascript('bridge.checkPassword($pairs,"$pubKey", "$pass")');
    if (res == null) {
      return false;
    }
    return true;
  }

  Future<bool> checkAddressFormat(String address, int ss58) async {
    final bool? res = await _runner
        ?.evalJavascript('bridge.checkAddressFormat("$address", $ss58)');
    return res ?? true;
  }

  Future<void> reload() async {
    return _runner?.reload();
  }

  Future<dynamic> evalJavascript(String code) async {
    return await _runner?.evalJavascript(code);
  }
}

import 'dart:async';

import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/bridge/bridgeChainData.dart';
import 'package:polkawallet_sdk/api/types/bridge/bridgeTokenBalance.dart';
import 'package:polkawallet_sdk/api/types/bridge/bridgeTxParams.dart';
import 'package:polkawallet_sdk/service/bridge.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';

class ApiBridge {
  ApiBridge(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceBridge service;

  Future<List<String>> getFromChainsAll() async {
    return service.getFromChainsAll();
  }

  Future<List<BridgeRouteData>> getRoutes() async {
    final res = await service.getRoutes();
    return res
        .map((e) => BridgeRouteData.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, BridgeChainData>> getChainsInfo() async {
    final data = await service.getChainsInfo();
    final Map<String, BridgeChainData> res = {};
    data.keys.forEach((chainName) {
      res[chainName] =
          BridgeChainData.fromJson(Map<String, dynamic>.from(data[chainName]));
    });
    return res;
  }

  Future<List<String>> connectFromChains(List<String> chains,
      {Map<String, List<String>>? nodeList}) async {
    return service.connectFromChains(chains, nodeList: nodeList);
  }

  Future<void> disconnectFromChains() async {
    service.disconnectFromChains();
  }

  Future<BridgeNetworkProperties> getNetworkProperties(String chain) async {
    final res = await service.getNetworkProperties(chain);
    return BridgeNetworkProperties.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> subscribeBalances(String chain, String address,
      Function(Map<String, BridgeTokenBalance>) callback) async {
    service.subscribeBalances(chain, address, (data) {
      final Map<String, BridgeTokenBalance> res = {};
      data.keys.forEach((token) {
        res[token] =
            BridgeTokenBalance.fromJson(Map<String, dynamic>.from(data[token]));
      });
      callback(res);
    });
  }

  Future<void> unsubscribeBalances(String chain, String address) async {
    service.unsubscribeBalances(chain, address);
  }

  Future<BridgeAmountInputConfig> getAmountInputConfig(String from, String to,
      String token, String address, String signer) async {
    final res =
        await service.getAmountInputConfig(from, to, token, address, signer);
    return BridgeAmountInputConfig.fromJson(Map<String, dynamic>.from(res));
  }

  Future<BridgeTxParams> getTxParams(String from, String to, String token,
      String address, String amount, int decimals, String signer) async {
    final res = await service.getTxParams(
        from, to, token, address, amount, decimals, signer);
    return BridgeTxParams.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> init({String? jsCode}) async {
    return await service.init(jsCode: jsCode);
  }

  Future<void> dispose() async {
    return service.dispose();
  }

  Future<String> estimateTxFee(
      String chainFrom, String txHex, String sender) async {
    final res = await service.estimateTxFee(chainFrom, txHex, sender);
    return res;
  }

  Future<Map?> sendTx(String chainFrom, Map txInfo, String password,
      String msgId, Map keyring) async {
    final res =
        await service.sendTx(chainFrom, txInfo, password, msgId, keyring);
    return res;
  }

  void subscribeReloadAction(String reloadKey, Function reloadAction) {
    service.subscribeReloadAction(reloadKey, reloadAction);
  }

  void unsubscribeReloadAction(String reloadKey) {
    service.unsubscribeReloadAction(reloadKey);
  }

  int getEvalJavascriptUID() {
    return service.getEvalJavascriptUID();
  }

  void addMsgHandler(String channel, Function onMessage) {
    service.addMsgHandler(channel, onMessage);
  }

  void removeMsgHandler(String channel) {
    service.removeMsgHandler(channel);
  }

  Future<bool> checkPassword(
      Map keyring, KeyPairData account, String pass) async {
    final res = await service.checkPassword(keyring, account.pubKey, pass);
    return res;
  }

  Future<bool> checkAddressFormat(String address, int ss58) async {
    return service.checkAddressFormat(address, ss58);
  }

  Future<void> reload() async {
    return service.reload();
  }
}

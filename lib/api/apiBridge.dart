import 'dart:async';

import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/bridge/bridgeChainData.dart';
import 'package:polkawallet_sdk/api/types/bridge/bridgeTokenBalance.dart';
import 'package:polkawallet_sdk/api/types/bridge/bridgeTxParams.dart';
import 'package:polkawallet_sdk/service/bridge.dart';

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

  Future<BridgeAmountInputConfig> getAmountInputConfig(
      String from, String to, String token, String address) async {
    final res = await service.getAmountInputConfig(from, to, token, address);
    return BridgeAmountInputConfig.fromJson(Map<String, dynamic>.from(res));
  }

  Future<BridgeTxParams> getTxParams(String from, String to, String token,
      String address, String amount, int decimals) async {
    final res =
        await service.getTxParams(from, to, token, address, amount, decimals);
    return BridgeTxParams.fromJson(Map<String, dynamic>.from(res));
  }
}

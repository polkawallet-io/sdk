import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/pairingData.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/payloadData.dart';
import 'package:polkawallet_sdk/service/walletConnect.dart';

class ApiWalletConnect {
  ApiWalletConnect(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceWalletConnect service;

  void initClient(
    String uri,
    String address,
    int chainId, {
    required Function(WCPeerMetaData, String) onPairing,
    required Function(Map) onPaired,
    required Function(WCCallRequestData) onCallRequest,
    required Function(String) onDisconnect,
    Map? cachedSession,
  }) {
    service.initClient(uri, address, chainId, onPairing: (Map proposal) {
      onPairing(WCPeerMetaData.fromJson(proposal['peerMeta']), proposal['uri']);
    }, onPaired: (Map session) {
      onPaired(session);
    }, onCallRequest: (Map payload) {
      onCallRequest(WCCallRequestData.fromJson(payload));
    }, onDisconnect: (uri) {
      onDisconnect(uri);
    }, cachedSession: cachedSession);
  }

  Future<void> disconnect() async {
    await service.disconnect();
  }

  Future<void> confirmPairing(bool approve) async {
    await service.confirmPairing(approve);
  }

  Future<void> confirmPairingV2(bool approve, String address) async {
    await service.confirmPairingV2(approve, address);
  }

  Future<WCCallRequestResult?> confirmPayload(
      int id, bool approve, String password, Map gasOptions) async {
    final res = await service.confirmPayload(id, approve, password, gasOptions);
    return WCCallRequestResult.fromJson(res);
  }

  Future<WCCallRequestResult?> confirmPayloadV2(
      int id, bool approve, String password, Map gasOptions) async {
    final res =
        await service.confirmPayloadV2(id, approve, password, gasOptions);
    return WCCallRequestResult.fromJson(res);
  }

  Future<void> changeAccount(String address) async {
    await service.changeAccount(address);
  }

  Future<void> changeAccountV2(String address) async {
    await service.changeAccountV2(address);
  }

  Future<void> changeNetwork(int chainId, String address) async {
    await service.changeNetwork(chainId, address);
  }

  Future<void> changeNetworkV2(int chainId, String address) async {
    await service.changeNetworkV2(chainId, address);
  }
}

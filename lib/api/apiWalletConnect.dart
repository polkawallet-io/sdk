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
    Map? cachedSession,
  }) {
    service.initClient(uri, address, chainId, cachedSession: cachedSession);
  }

  void subscribeEvents({
    required Function(WCPairingData?, WCProposerMeta?, String?) onPairing,
    required Function(Map) onPaired,
    required Function(WCCallRequestData) onCallRequest,
    required Function(String) onDisconnect,
    String? uri,
  }) {
    service.subscribeEvents(
        onPairing: (Map proposal) {
          final wcVersion2 = proposal['uri'] != null;
          if (wcVersion2) {
            final prop = WCPairingData.fromJson(proposal['proposal']);
            onPairing(prop, prop.params?.proposer?.metadata, proposal['uri']);
          } else {
            onPairing(
                null, WCProposerMeta.fromJson(proposal['peerMeta']), null);
          }
        },
        onPaired: (Map session) {
          onPaired(session);
        },
        onCallRequest: (Map payload) {
          onCallRequest(WCCallRequestData.fromJson(payload));
        },
        onDisconnect: (uri) {
          onDisconnect(uri);
        },
        uri: uri);
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

  Future<void> changeNetwork(String chainId, String address) async {
    await service.changeNetwork(chainId, address);
  }

  Future<void> changeNetworkV2(String chainId, String address) async {
    await service.changeNetworkV2(chainId, address);
  }

  Future<void> injectCacheDataV2(Map cache, String address) async {
    await service.injectCacheDataV2(cache, address);
  }

  Future<void> deletePairingV2(String topic) async {
    await service.deletePairingV2(topic);
  }

  Future<void> disconnectV2(String topic) async {
    await service.disconnectV2(topic);
  }
}

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
    String address, {
    required Function(WCPeerMetaData) onPairing,
    required Function() onPaired,
    required Function(WCCallRequestData) onCallRequest,
    required Function() onDisconnect,
  }) {
    service.initClient(uri, address, onPairing: (Map peerMeta) {
      onPairing(WCPeerMetaData.fromJson(peerMeta));
    }, onPaired: () {
      onPaired();
    }, onCallRequest: (Map payload) {
      onCallRequest(WCCallRequestData.fromJson(payload));
    }, onDisconnect: () {
      onDisconnect();
    });
  }

  Future<void> disconnect() async {
    await service.disconnect();
  }

  Future<void> confirmPairing(bool approve) async {
    await service.confirmPairing(approve);
  }

  Future<WCCallRequestResult?> confirmPayload(
      int id, bool approve, String password, Map gasOptions) async {
    final res = await service.confirmPayload(id, approve, password, gasOptions);
    return WCCallRequestResult.fromJson(res);
  }
}

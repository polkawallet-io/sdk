import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/pairingData.dart';
import 'package:polkawallet_sdk/service/walletConnect.dart';

class ApiWalletConnect {
  ApiWalletConnect(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceWalletConnect service;

  Future<WCPairingData> connect(String uri, Function(Map) onPayload) async {
    final Map res = await service.connect(uri, (Map payload) {
      onPayload(payload);
    });
    return WCPairingData.fromJson(res);
  }

  Future<Map> approvePairing(WCPairingData proposal, String address) async {
    final Map res = await service.approvePairing(proposal.toJson(), address);
    return res;
  }

  Future<Map> rejectPairing(WCPairingData proposal) async {
    final Map res = await service.rejectPairing(proposal.toJson());
    return res;
  }

  Future<Map> payloadRespond(Map response) async {
    final Map res = await service.payloadRespond(response);
    return res;
  }
}

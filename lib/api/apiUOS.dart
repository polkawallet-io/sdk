import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/service/uos.dart';

/// Support offline-signature as a hot-wallet:
/// 1. makeQrCode
/// 2. addSignatureAndSend: send tx with address of step1 & signature of step2.
class ApiUOS {
  ApiUOS(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceUOS service;

  /// [onStatusChange] is a callback when tx status change.
  /// @return txHash [string] if tx finalized success.
  Future<Map?> addSignatureAndSend(
    String address,
    signed,
    Function(String) onStatusChange,
  ) async {
    final res = await service.addSignatureAndSend(
      address,
      signed,
      onStatusChange,
    );
    if (res?['error'] != null) {
      throw Exception(res?['error']);
    }
    return res;
  }

  Future<Map?> makeQrCode(TxInfoData txInfo, List params,
      {String? rawParam}) async {
    final Map? res = await service.makeQrCode(
      txInfo.toJson(),
      params,
      rawParam: rawParam,
      ss58: apiRoot.connectedNode!.ss58,
    );
    return res;
  }
}

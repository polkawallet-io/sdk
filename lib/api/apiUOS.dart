import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/api/types/uosQrParseResultData.dart';
import 'package:polkawallet_sdk/service/uos.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

/// Steps to complete offline-signature as a cold-wallet:
/// 1. parseQrCode: parse raw data of QR code, and get signer address from it.
/// 2. signAsync: sign the extrinsic with password, get signature.
/// 3. addSignatureAndSend: send tx with address of step1 & signature of step2.
///
/// Support offline-signature as a hot-wallet: makeQrCode
class ApiUOS {
  ApiUOS(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceUOS service;

  /// parse data of QR code.
  /// @return: [UosQrParseResultData]
  Future<UosQrParseResultData> parseQrCode(Keyring keyring, String data) async {
    final res = await service.parseQrCode(keyring.store.list.toList(), data);
    return UosQrParseResultData.fromJson(res);
  }

  /// this function must be called after parseQrCode.
  /// @return: signature [String]
  Future<String?> signAsync(String chain, password) async {
    return service.signAsync(chain, password);
  }

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

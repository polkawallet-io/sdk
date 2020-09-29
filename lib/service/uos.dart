import 'package:polkawallet_sdk/service/index.dart';

/// Steps to complete offline-signature as a cold-wallet:
/// 1. parseQrCode: parse raw data of QR code, and get signer address from it.
/// 2. signAsync: sign the extrinsic with password, get signature.
/// 3. addSignatureAndSend: send tx with address of step1 & signature of step2.
///
/// Support offline-signature as a hot-wallet: makeQrCode
class ServiceUOS {
  ServiceUOS(this.serviceRoot);

  final SubstrateService serviceRoot;

  /// parse data of QR code.
  /// @return: signer pubKey [String]
  Future<String> parseQrCode(List keyPairs, String data) async {
    final res = await serviceRoot.webView
        .evalJavascript('keyring.parseQrCode("$data")');
    if (res['error'] != null) {
      throw Exception(res['error']);
    }

    final pubKeyAddressMap =
        await serviceRoot.account.decodeAddress([res['signer']]);
    final pubKey = pubKeyAddressMap.keys.toList()[0];
    final accIndex = keyPairs.indexWhere((e) => e['pubKey'] == pubKey);
    if (accIndex < 0) {
      throw Exception('signer: ${res['signer']} not found.');
    }
    return pubKey;
  }

  /// this function must be called after parseQrCode.
  /// @return: signature [String]
  Future<String> signAsync(String password) async {
    final res = await serviceRoot.webView
        .evalJavascript('keyring.signAsync(api, "$password")');
    if (res['error'] != null) {
      throw Exception(res['error']);
    }

    return res['signature'];
  }

  Future<Map> addSignatureAndSend(
    String address,
    signed,
    Function(String) onStatusChange,
  ) async {
    final msgId = "onStatusChange${serviceRoot.webView.getEvalJavascriptUID()}";
    serviceRoot.webView.addMsgHandler(msgId, onStatusChange);

    final Map res = await serviceRoot.webView
        .evalJavascript('account.addSignatureAndSend("$address", "$signed")');
    serviceRoot.webView.removeMsgHandler(msgId);

    return res;
  }

  // Future<Map> makeQrCode(Map txInfo, List params, {String rawParam}) async {
  //   String param = rawParam != null ? rawParam : jsonEncode(params);
  //   final Map res = await apiRoot.evalJavascript(
  //     'account.makeTx(${jsonEncode(txInfo)}, $param)',
  //     allowRepeat: true,
  //   );
  //   return res;
  // }

}

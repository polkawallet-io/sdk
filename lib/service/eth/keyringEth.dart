import 'dart:convert';

import 'package:polkawallet_sdk/api/types/addressIconData.dart';
import 'package:polkawallet_sdk/ethers/apiEthers.dart';
import 'package:polkawallet_sdk/service/index.dart';

const default_derive_path = "m/44'/60'/0'/0/0";

class ServiceKeyringEth {
  ServiceKeyringEth(this.serviceRoot);

  final SubstrateService serviceRoot;

  /// Generate a set of new mnemonic.
  Future<AddressIconDataWithMnemonic> generateMnemonic(
      {int? index, String? mnemonic}) async {
    final dynamic acc = await serviceRoot.webView!
        .evalJavascript('eth.keyring.gen("$mnemonic",$index)');
    return AddressIconDataWithMnemonic.fromJson(acc);
  }

  /// get address and avatar from mnemonic.
  Future<dynamic> addressFromMnemonic(
      {required String derivePath, required String mnemonic}) async {
    print('eth.keyring.addressFromMnemonic("$mnemonic","$derivePath")');
    final dynamic acc = await serviceRoot.webView!.evalJavascript(
        'eth.keyring.addressFromMnemonic("$mnemonic","$derivePath")');
    return acc;
  }

  /// get address and avatar from privateKey.privateKey: string
  Future<dynamic> addressFromPrivateKey({required String privateKey}) async {
    final dynamic acc = await serviceRoot.webView!
        .evalJavascript('eth.keyring.addressFromPrivateKey("$privateKey")');
    return acc;
  }

  /// Import keyPair from mnemonic, privateKey or keystore.
  /// keyType: string, key: string, derivePath: string, password: string
  Future<Map> importAccount({
    required EVMKeyType keyType,
    required String key,
    required String name,
    required String password,
    String derivePath = default_derive_path,
  }) async {
    // generate json from js-api
    final String type = keyType.toString().split('.')[1];
    if (type == "keystore") {
      key = key.replaceAll("\"", "\\\"");
    }
    String code =
        'eth.keyring.recover("$type", "$key", "$derivePath", "$password")';
    code = code.replaceAll(RegExp(r'\t|\n|\r'), '');
    final Map acc = _formatAccountData(
        (await serviceRoot.webView!.evalJavascript(code)) ?? {});

    return {...acc, type: key, 'name': name};
  }

  /// check password of account
  Future<bool> checkPassword(
      {required String keystore, required String pass}) async {
    final res = await serviceRoot.webView!
        .evalJavascript('eth.keyring.checkPassword($keystore, "$pass")');
    //An error Message is displayed if it fails :{ success: false, error: err.message }
    return res["success"];
  }

  /// change password of account
  Future<Map> changePassword(
      {required String keystore,
      required String passOld,
      required String passNew}) async {
    final res = await serviceRoot.webView!.evalJavascript(
        'eth.keyring.changePassword($keystore, "$passOld", "$passNew")');
    return _formatAccountData(res ?? {});
  }

  /// sign message with private key of an account.
  Future<dynamic> signMessage(
      {required String message,
      required String keystore,
      required String pass}) async {
    final res = await serviceRoot.webView!.evalJavascript(
        'eth.keyring.signMessage("$message", $keystore, "$pass")');
    return res;
  }

  /// get signer of a signature. so we can verify the signer.
  Future<dynamic> verifySignature(
      {required String message, required String signature}) async {
    final res = await serviceRoot.webView!.evalJavascript(
        'eth.keyring.verifySignature("$message", "$signature")');
    return res;
  }

  /// Get icons of addresses
  /// return svg strings
  Future<List?> getAddressIcons(List addresses) async {
    final dynamic res = await serviceRoot.webView!
        .evalJavascript('eth.account.genIcons(${jsonEncode(addresses)})');
    return res;
  }

  Map _formatAccountData(Map acc) {
    final keystore = jsonDecode(acc['keystore'] ?? '{}');
    return {
      'error': acc['error'],
      'address': acc['address'],
      'id': keystore['id'],
      'version': keystore['version'],
      'crypto': keystore['Crypto'],
    };
  }
}

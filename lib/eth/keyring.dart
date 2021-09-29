import 'dart:convert';
import 'package:polkawallet_sdk/api/apiETHKeyring.dart';
import 'package:polkawallet_sdk/service/index.dart';
import 'package:polkawallet_sdk/storage/types/GenerateMnemonicData.dart';

class ETHServiceKeyring {
  ETHServiceKeyring(this.serviceRoot);

  final SubstrateService serviceRoot;

  /// Generate a set of new mnemonic.
  Future<GenerateMnemonicData> generateMnemonic(
      {int? index, String? mnemonic}) async {
    final dynamic acc = await serviceRoot.webView!
        .evalJavascript('eth.keyring.gen("$mnemonic",$index)');
    return GenerateMnemonicData.fromJson(acc);
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
  Future<dynamic> importAccount({
    required ETH_KeyType keyType,
    required String key,
    required String derivePath,
    required String name,
    required String password,
  }) async {
    // generate json from js-api
    final String type = keyType.toString().split('.')[1];
    String code =
        'eth.keyring.recover("$type", "$key", "$derivePath", "$password")';
    code = code.replaceAll(RegExp(r'\t|\n|\r'), '');
    dynamic acc = await serviceRoot.webView!.evalJavascript(code);
    acc["name"] = name;

    return acc;
  }

  /// check password of account
  Future<bool> checkPassword(
      {required String keystore, required String pass}) async {
    keystore = keystore.replaceAll("\"", "\\\"");
    final res = await serviceRoot.webView!
        .evalJavascript('eth.keyring.checkPassword("$keystore", "$pass")');
    //An error Message is displayed if it fails :{ success: false, error: err.message }
    return res["success"];
  }

  /// change password of account
  Future<Map?> changePassword(
      {required String keystore,
      required String passOld,
      required String passNew}) async {
    keystore = keystore.replaceAll("\"", "\\\"");
    final res = await serviceRoot.webView!.evalJavascript(
        'eth.keyring.changePassword("$keystore", "$passOld", "$passNew")');
    return res;
  }

  /// sign message with private key of an account.
  Future<dynamic> signMessage(
      {required String message,
      required String keystore,
      required String pass}) async {
    keystore = keystore.replaceAll("\"", "\\\"");
    final res = await serviceRoot.webView!.evalJavascript(
        'eth.keyring.signMessage("$message", "$keystore", "$pass")');
    return res;
  }

  /// get signer of a signature. so we can verify the signer.
  Future<dynamic> verifySignature(
      {required String message, required String signature}) async {
    final res = await serviceRoot.webView!.evalJavascript(
        'eth.keyring.verifySignature("$message", "$signature")');
    return res;
  }

  Future<List?> getPubKeyIconsMap(List<String?> pubKeys) async {
    return await serviceRoot.eth.account.getAddressIcons(pubKeys);
  }

  Map updateKeyPairMetaData(Map acc, String? name) {
    acc['name'] = name;
    // acc['meta']['name'] = name;
    // if (acc['meta']['whenCreated'] == null) {
    //   acc['meta']['whenCreated'] = DateTime.now().millisecondsSinceEpoch;
    // }
    // acc['meta']['whenEdited'] = DateTime.now().millisecondsSinceEpoch;
    return acc;
  }
}

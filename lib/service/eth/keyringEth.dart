import 'dart:convert';

import 'package:polkawallet_sdk/api/types/addressIconData.dart';
import 'package:polkawallet_sdk/ethers/apiEthers.dart';
import 'package:polkawallet_sdk/service/index.dart';
import 'package:polkawallet_sdk/storage/keyringEVM.dart';

const default_derive_path = "m/44'/60'/0'/0/0";

class ServiceKeyringEth {
  ServiceKeyringEth(this.serviceRoot);

  final SubstrateService serviceRoot;

  Future<void> injectKeyPairsToWebView(KeyringEVM keyring) async {
    if (keyring.store.list.length > 0) {
      final String pairs = jsonEncode(keyring.store.list);
      serviceRoot.webView!.evalJavascript('eth.keyring.initKeys($pairs)');
    }
  }

  /// Generate a set of new mnemonic.
  Future<AddressIconDataWithMnemonic> generateMnemonic(
      {int? index, String? mnemonic}) async {
    final dynamic acc = await serviceRoot.webView!
        .evalJavascript('eth.keyring.gen("$mnemonic",$index)');
    return AddressIconDataWithMnemonic.fromJson(acc);
  }

  /// get address and avatar from mnemonic.
  Future<dynamic> addressFromMnemonic(
      {String? derivePath, required String mnemonic}) async {
    final dynamic acc = await serviceRoot.webView!.evalJavascript(
        'eth.keyring.addressFromMnemonic("$mnemonic","${derivePath ?? default_derive_path}")');
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
      {required String address, required String pass}) async {
    final res = await serviceRoot.webView!
        .evalJavascript('eth.keyring.checkPassword("$address", "$pass")');
    //An error Message is displayed if it fails :{ success: false, error: err.message }
    return res["success"];
  }

  /// change password of account
  Future<Map> changePassword(
      {required String address,
      required String passOld,
      required String passNew}) async {
    final res = await serviceRoot.webView!.evalJavascript(
        'eth.keyring.changePassword("$address", "$passOld", "$passNew")');
    return _formatAccountData(res ?? {});
  }

  /// sign message with private key of an account.
  Future<dynamic> signMessage(
      {required String message,
      required String address,
      required String pass}) async {
    final res = await serviceRoot.webView!.evalJavascript(
        'eth.keyring.signMessage("$message", "$address", "$pass")');
    return res;
  }

  /// get signer of a signature. so we can verify the signer.
  Future<Map> verifySignature(
      {required String message, required String signature}) async {
    final res = await serviceRoot.webView!.evalJavascript(
        'eth.keyring.verifySignature("$message", "$signature")');
    return res;
  }

  Future<Map> transfer(
      {required String token,
      required double amount,
      required String to,
      required String sender,
      required String pass,
      required Map gasOptions,
      required Function(Map) onStatusChange}) async {
    final code =
        'eth.keyring.transfer("$token", $amount, "$to", "$sender", "$pass", ${jsonEncode(gasOptions)})';
    print('send evm transfer:');
    print(code);
    final res = await serviceRoot.webView!.evalJavascript(code);
    if (res != null && res['hash'] != null) {
      serviceRoot.webView!.addMsgHandler(res['hash'], (Map res) {
        onStatusChange(res);
        if ((res['confirmNumber'] ?? -1) > 1) {
          serviceRoot.webView!.removeMsgHandler(res['hash']);
        }
      });
    }
    return res;
  }

  Future<int> estimateTransferGas(
      {required String token,
      required double amount,
      required String to,
      required String from}) async {
    final res = await serviceRoot.webView!.evalJavascript(
        'eth.keyring.estimateTransferGas("$token", $amount, "$to", "$from")');
    return res ?? 200000;
  }

  Future<String?> getGasPrice() async {
    final res =
        await serviceRoot.webView!.evalJavascript('eth.keyring.getGasPrice()');
    return res;
  }

  Map _formatAccountData(Map acc) {
    final keystore = jsonDecode(acc['keystore'] ?? '{}');
    return {
      'error': acc['error'],
      'address': acc['address'],
      'id': keystore['id'],
      'version': keystore['version'],
      'crypto': keystore['Crypto'] ?? keystore['crypto'],
    };
  }

  Future<List> renderEthRequest(Map payload) async {
    final List res = await serviceRoot.webView!.evalJavascript(
        'eth.keyring.renderEthRequest(${jsonEncode(payload)})',
        wrapPromise: false);
    return res;
  }

  Future<Map> signEthRequest(
      Map payload, String address, String pass, Map gasOptions) async {
    final Map res = await serviceRoot.webView!.evalJavascript(
        'eth.keyring.signEthRequest(${jsonEncode(payload)}, "$address", "$pass", ${jsonEncode(gasOptions)})');
    return res;
  }
}

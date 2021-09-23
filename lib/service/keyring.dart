import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/service/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/GenerateMnemonicData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';

class ServiceKeyring {
  ServiceKeyring(this.serviceRoot);

  final SubstrateService serviceRoot;

  Future<Map?> getPubKeyAddressMap(List keyPairs, List<int> ss58) async {
    final List<String> pubKeys =
        keyPairs.map((e) => e['pubKey'].toString()).toList();
    return await serviceRoot.account!.encodeAddress(pubKeys, ss58);
  }

  Future<List?> getPubKeyIconsMap(List<String?> pubKeys) async {
    return await serviceRoot.account!.getPubKeyIcons(pubKeys);
  }

  Future<Map?> injectKeyPairsToWebView(Keyring keyring) async {
    if (keyring.store.list.length > 0) {
      final String pairs = jsonEncode(keyring.store.list);
      final ss58 = keyring.store.ss58List;
      final res = Map<String, Map>.from(await serviceRoot.webView!
          .evalJavascript('keyring.initKeys($pairs, ${jsonEncode(ss58)})'));

      final contacts = await getPubKeyAddressMap(keyring.store.contacts, ss58);
      res.forEach((key, value) {
        res[key]!.addAll(contacts![key]);
      });

      keyring.store.updatePubKeyAddressMap(res);
      return res;
    }
    return null;
  }

  Map updateKeyPairMetaData(Map acc, String? name) {
    acc['name'] = name;
    acc['meta']['name'] = name;
    if (acc['meta']['whenCreated'] == null) {
      acc['meta']['whenCreated'] = DateTime.now().millisecondsSinceEpoch;
    }
    acc['meta']['whenEdited'] = DateTime.now().millisecondsSinceEpoch;
    return acc;
  }

  /// Generate a set of new mnemonic.
  Future<GenerateMnemonicData> generateMnemonic(int ss58,
      {CryptoType cryptoType = CryptoType.sr25519,
      String derivePath = '',
      String? key}) async {
    final String crypto = cryptoType.toString().split('.')[1];
    final dynamic acc = await serviceRoot.webView!
        .evalJavascript('keyring.gen("$key",$ss58,"$crypto","$derivePath")');
    return GenerateMnemonicData.fromJson(acc);
  }

  /// Import account from mnemonic/rawSeed/keystore.
  /// param [cryptoType] can be `sr25519`(default) or `ed25519`.
  /// return [null] if import failed.
  Future<dynamic> importAccount({
    required KeyType keyType,
    required String key,
    required name,
    required password,
    CryptoType cryptoType = CryptoType.sr25519,
    String derivePath = '',
  }) async {
    // generate json from js-api
    final String type = keyType.toString().split('.')[1];
    final String crypto = cryptoType.toString().split('.')[1];
    String code =
        'keyring.recover("$type", "$crypto", \'$key$derivePath\', "$password")';
    code = code.replaceAll(RegExp(r'\t|\n|\r'), '');
    final dynamic acc = await serviceRoot.webView!.evalJavascript(code);
    if (acc == null || acc['error'] != null) {
      return acc;
    }

    // add metadata to json
    updateKeyPairMetaData(acc, name);

    return acc;
  }

  /// check password of account
  Future<bool> checkPassword(String? pubKey, pass) async {
    final res = await serviceRoot.webView!
        .evalJavascript('keyring.checkPassword("$pubKey", "$pass")');
    if (res == null) {
      return false;
    }
    return true;
  }

  /// change password of account
  Future<Map?> changePassword(String? pubKey, passOld, passNew) async {
    final res = await serviceRoot.webView!.evalJavascript(
        'keyring.changePassword("$pubKey", "$passOld", "$passNew")');
    return res;
  }

  Future<String?> checkDerivePath(
      String seed, path, CryptoType cryptoType) async {
    final String crypto = cryptoType.toString().split('.')[1];
    dynamic res = await serviceRoot.webView!
        .evalJavascript('keyring.checkDerivePath("$seed", "$path", "$crypto")');
    return res;
  }

  Future<Map?> signAsExtension(String password, Map args) async {
    final String call = args['msgType'] == 'pub(bytes.sign)'
        ? 'signBytesAsExtension'
        : 'signTxAsExtension';
    final res = await serviceRoot.webView!.evalJavascript(
      'keyring.$call("$password", ${jsonEncode(args['request'])})',
      allowRepeat: true,
    );
    return res;
  }

  Future<Map?> signatureVerify(String message, signature, address) async {
    final res = await serviceRoot.webView!.evalJavascript(
      'keyring.verifySignature("$message", "$signature", "$address")',
      allowRepeat: true,
    );

    if (res == null) {
      return null;
    }
    return res;
  }
}

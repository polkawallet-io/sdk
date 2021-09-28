import 'package:polkawallet_sdk/eth/keyring.dart';
import 'package:polkawallet_sdk/storage/keyringETH.dart';
import 'package:polkawallet_sdk/storage/types/GenerateMnemonicData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairETHData.dart';

import 'api.dart';

enum ETH_KeyType { mnemonic, privateKey, keystore }

class ApiETHKeyring {
  ApiETHKeyring(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ETHServiceKeyring? service;

  /// Generate a set of new mnemonic.
  Future<GenerateMnemonicData> generateMnemonic(
      {int? index, String? mnemonic}) async {
    final mnemonicData =
        await service!.generateMnemonic(index: index, mnemonic: mnemonic);
    return mnemonicData;
  }

  /// get address and avatar from mnemonic.
  Future<GenerateMnemonicData> addressFromMnemonic(
      {required String derivePath, required String mnemonic}) async {
    final acc = await service!
        .addressFromMnemonic(derivePath: derivePath, mnemonic: mnemonic);
    if (acc['error'] != null) {
      throw Exception(acc['error']);
    }
    return GenerateMnemonicData.fromJson(acc);
  }

  /// get address and avatar from privateKey.privateKey: string
  Future<dynamic> addressFromPrivateKey({required String privateKey}) async {
    final acc = await service!.addressFromPrivateKey(privateKey: privateKey);
    if (acc['error'] != null) {
      throw Exception(acc['error']);
    }
    return GenerateMnemonicData.fromJson(acc);
  }

  Future<Map?> importAccount({
    required ETH_KeyType keyType,
    required String key,
    required String derivePath,
    required String password,
  }) async {
    final dynamic acc = await service!.importAccount(
      keyType: keyType,
      key: key,
      derivePath: derivePath,
      password: password,
    );
    if (acc == null) {
      return null;
    }
    if (acc['error'] != null) {
      throw Exception(acc['error']);
    }

    return acc;
  }

  /// check password of account
  Future<bool> checkPassword(
      {required String keystore, required String pass}) async {
    final res = await service!.checkPassword(keystore: keystore, pass: pass);
    return res;
  }

  /// change password of account
  Future<KeyPairETHData?> changePassword(
      {required KeyringETH keyring,
      required String passOld,
      required String passNew}) async {
    // 1. change password of keyPair in webView
    final res = await service!.changePassword(
        keystore: keyring.current.keystore!,
        passNew: passOld,
        passOld: passNew);
    if (res == null) {
      return null;
    }
    // 2. if success in webView, then update encrypted seed in local storage.
    keyring.store.updateEncryptedSeed(
        address: keyring.current.address!, passOld: passOld, passNew: passNew);

    KeyPairETHData data = KeyPairETHData.fromJson(res as Map<String, dynamic>);
    // update keyPair date in storage
    keyring.store.updateAccount(data);
    return data;
  }

  /// sign message with private key of an account.
  Future<dynamic> signMessage(
      {required String message,
      required String keystore,
      required String pass}) async {
    final res = await service!
        .signMessage(message: message, keystore: keystore, pass: pass);

    if (res['error'] != null) {
      throw Exception(res['error']);
    }
    return res;
  }

  /// get signer of a signature. so we can verify the signer.
  Future<dynamic> verifySignature(
      {required String message, required String signature}) async {
    final res =
        await service!.verifySignature(message: message, signature: signature);

    if (res['error'] != null) {
      throw Exception(res['error']);
    }
    return res;
  }
}

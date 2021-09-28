import 'dart:async';

import 'package:aes_ecb_pkcs5_flutter/aes_ecb_pkcs5_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_sdk/api/apiETHKeyring.dart';
import 'package:polkawallet_sdk/utils/index.dart';

import 'localStorage.dart';
import 'types/keyPairETHData.dart';

class KeyringETH {
  late KeyringPrivateStore store;

  Future<void> init() async {
    store = KeyringPrivateStore();
    await store.init();
  }

  KeyPairETHData get current {
    var keypairs = keyPairs;
    if (keypairs.length > 0) {
      return keypairs.firstWhere(
          (element) => element.address == store.currentAddress,
          orElse: () => KeyPairETHData());
    }
    return KeyPairETHData();
  }

  List<KeyPairETHData> get optionals {
    final res = keyPairs;
    res.removeWhere((e) => e.pubKey == current.pubKey);
    return res;
  }

  List<KeyPairETHData> get keyPairs {
    return store.keyPairs
        .toList()
        .map((e) => KeyPairETHData.fromJson(e))
        .toList();
  }
}

class KeyringPrivateStore {
  final KeyringETHStorage _storage = KeyringETHStorage();

  String? get currentAddress => _storage.currentAddress.val;
  void setCurrentAddress(String? address) {
    _storage.currentAddress.val = address;
  }

  List get keyPairs => _storage.keyPairs.val;

  Future<void> init() async {
    await GetStorage.init(sdk_storage_eth_key);
  }

  void updateAccount(KeyPairETHData data) {
    _storage.currentAddress.val = data.address;
    _updateKeyPair(data);
  }

  Future<void> _updateKeyPair(KeyPairETHData data) async {
    final List pairs = _storage.keyPairs.val.toList();
    pairs.removeWhere((e) => e['address'] == data.address);
    pairs.add(data);
    _storage.keyPairs.val = pairs;
  }

  Future<void> updateEncryptedSeed(
      {required String address,
      required String passOld,
      required String passNew}) async {
    final seed = await (getDecryptedSeed(address: address, password: passOld)
        as FutureOr<Map<String, dynamic>>);
    encryptSeedAndSave(
        address: address,
        seed: seed['seed'],
        seedType: seed['type'],
        password: passNew);
  }

  Future<Map<String, dynamic>?> getDecryptedSeed(
      {required String address, required String password}) async {
    final key = Encrypt.passwordToEncryptKey(password);
    final mnemonic = _storage.encryptedMnemonics.val[address];
    if (mnemonic != null) {
      final res = {'type': ETH_KeyType.mnemonic.toString().split('.')[1]};
      try {
        res['seed'] = await FlutterAesEcbPkcs5.decryptString(mnemonic, key);
      } catch (err) {
        print(err);
      }
      return res;
    }
    final privateKey = _storage.encryptedPrivateKey.val[address];
    if (privateKey != null) {
      final res = {'type': ETH_KeyType.privateKey.toString().split('.')[1]};
      try {
        res['seed'] = await FlutterAesEcbPkcs5.decryptString(privateKey, key);
      } catch (err) {
        print(err);
      }
      return res;
    }
    return null;
  }

  Future<void> encryptSeedAndSave(
      {required String address,
      required String seed,
      required String seedType,
      required String password}) async {
    final String key = Encrypt.passwordToEncryptKey(password);
    final String encrypted = await FlutterAesEcbPkcs5.encryptString(seed, key);

    // and save to new storage
    if (seedType == ETH_KeyType.mnemonic.toString().split('.')[1]) {
      final mnemonics = Map.from(_storage.encryptedMnemonics.val);
      mnemonics.addAll({address: encrypted});
      _storage.encryptedMnemonics.val = mnemonics;
      return;
    }
    if (seedType == ETH_KeyType.privateKey.toString().split('.')[1]) {
      final seeds = Map.from(_storage.encryptedPrivateKey.val);
      seeds.addAll({address: encrypted});
      _storage.encryptedPrivateKey.val = seeds;
    }
  }

  Future<void> addAccount(Map acc) async {
    final pairs = _storage.keyPairs.val.toList();
    // remove duplicated account and add a new one
    pairs.retainWhere((e) => e['address'] != acc['address']);
    pairs.add(acc);
    _storage.keyPairs.val = pairs;

    setCurrentAddress(acc['address']);
  }
}

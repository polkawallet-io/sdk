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

  List<KeyPairETHData> get optionals {
    final res = keyPairs;
    res.removeWhere((e) => e.address == current.address);
    return res;
  }

  KeyPairETHData get current {
    var keypairs = keyPairs;
    if (keypairs.length > 0) {
      return keypairs.firstWhere((element) {
        return element.address == store.currentAddress;
      }, orElse: () => KeyPairETHData());
    }
    return KeyPairETHData();
  }

  List<KeyPairETHData> get keyPairs {
    return store.keyPairs
        .toList()
        .map((e) => KeyPairETHData.fromJson(e))
        .toList();
  }

  List<KeyPairETHData> get contacts {
    return store.contacts
        .toList()
        .map((e) => KeyPairETHData.fromJson(e))
        .toList();
  }

  List<KeyPairETHData> get allWithContacts {
    final res = keyPairs;
    res.addAll(contacts);
    res.forEach((element) => print("allWithContacts==${element.toJson()}"));
    return res;
  }
}

class KeyringPrivateStore {
  final KeyringETHStorage _storage = KeyringETHStorage();

  Map<String, String> _iconsMap = {};
  String? get currentAddress => _storage.currentAddress.val;
  void setCurrentAddress(String? address) {
    _storage.currentAddress.val = address;
  }

  List get keyPairs {
    return _formatAccount(_storage.keyPairs.val.toList());
  }

  List get contacts {
    return _formatAccount(_storage.contacts.val.toList());
  }

  List _formatAccount(List ls) {
    ls.forEach((e) {
      e['icon'] = _iconsMap[e['address']];
    });
    return ls;
  }

  Future<void> init() async {
    await GetStorage.init(sdk_storage_eth_key);
  }

  void updateAccount(Map acc) {
    _storage.currentAddress.val = acc["address"];
    _updateKeyPair(acc);
  }

  Future<void> _updateKeyPair(Map acc) async {
    final List pairs = _storage.keyPairs.val.toList();
    pairs.removeWhere((e) => e['address'] == acc["address"]);
    pairs.add(acc);
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

  void updateIconsMap(Map<String, String> data) {
    _iconsMap.addAll(data);
  }

  Future<bool> checkSeedExist(ETH_KeyType keyType, String address) async {
    switch (keyType) {
      case ETH_KeyType.mnemonic:
        return _storage.encryptedMnemonics.val[address] != null;
      case ETH_KeyType.privateKey:
        return _storage.encryptedPrivateKey.val[address] != null;
      default:
        return false;
    }
  }

  // Future<void> deleteAccount(String? pubKey) async {
  //   _deleteKeyPair(pubKey);

  //   final mnemonics = Map.of(_storage.encryptedMnemonics.val);
  //   mnemonics.removeWhere((key, _) => key == pubKey);
  //   _storage.encryptedMnemonics.val = mnemonics;
  //   final seeds = Map.of(_storage.encryptedRawSeeds.val);
  //   seeds.removeWhere((key, _) => key == pubKey);
  //   _storage.encryptedRawSeeds.val = seeds;
  // }

  // Future<void> _deleteKeyPair(String? pubKey) async {
  //   final List pairs = _storage.keyPairs.val.toList();
  //   pairs.removeWhere((e) => e['pubKey'] == pubKey);
  //   _storage.keyPairs.val = pairs;

  //   if (pairs.length > 0) {
  //     setCurrentAddress(pairs[0]['address']);
  //   } else if (externals.length > 0) {
  //     setCurrentPubKey(externals[0]['pubKey']);
  //   } else {
  //     setCurrentPubKey('');
  //   }
  // }
}

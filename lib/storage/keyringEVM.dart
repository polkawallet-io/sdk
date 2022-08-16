import 'dart:async';

import 'package:flutter_aes_ecb_pkcs5/flutter_aes_ecb_pkcs5.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_sdk/ethers/apiEthers.dart';
import 'package:polkawallet_sdk/storage/localStorage.dart';
import 'package:polkawallet_sdk/storage/types/ethWalletData.dart';
import 'package:polkawallet_sdk/utils/index.dart';

/// A [KeyringEVM] instance maintains the local storage
/// of EVM key-pairs for users.
/// We need to pass the storage instance to [WalletSDK]'s
/// keyringEVM api for account management.
class KeyringEVM {
  late KeyringEVMPrivateStore store;

  EthWalletData get current {
    final list = allAccounts;
    if (list.length > 0) {
      final i = list.indexWhere((e) => e.address == store.currentAddress);
      return i >= 0 ? list[i] : list[0];
    }
    return EthWalletData();
  }

  void setCurrent(EthWalletData acc) {
    store.setCurrentAddress(acc.address);
  }

  List<EthWalletData> get keyPairs {
    return store.list.map((e) => EthWalletData.fromJson(e)).toList();
  }

  List<EthWalletData> get externals {
    return store.externals.map((e) => EthWalletData.fromJson(e)).toList();
  }

  List<EthWalletData> get contacts {
    return store.contacts.map((e) => EthWalletData.fromJson(e)).toList();
  }

  List<EthWalletData> get allAccounts {
    final res = keyPairs;
    res.addAll(externals);
    return res;
  }

  List<EthWalletData> get allWithContacts {
    final res = keyPairs;
    res.addAll(contacts);
    return res;
  }

  List<EthWalletData> get optionals {
    final res = allAccounts;
    res.removeWhere((e) => e.address == current.address);
    return res;
  }

  Future<void> init() async {
    store = KeyringEVMPrivateStore();
    await store.init();

    // The first call is 0, so I call it once
    print(
        "_keyringEVM.keyPairs.length===${this.keyPairs.length}====_keyringEVM.contacts.length${this.contacts.length}");
  }
}

class KeyringEVMPrivateStore {
  final KeyringEVMStorage _storage = KeyringEVMStorage();

  Map<String, String> _iconsMap = {};

  String? get currentAddress => _storage.currentAddress.val;
  void setCurrentAddress(String? address) {
    _storage.currentAddress.val = address;
  }

  List get list {
    return _formatAccount(_storage.keyPairs.val.toList());
  }

  List get externals {
    final ls = _storage.contacts.val.toList();
    ls.retainWhere((e) => e['observation'] ?? false);
    return _formatAccount(ls);
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

  /// the [GetStorage] package needs to be initiated before use.
  Future<void> init() async {
    await GetStorage.init(sdk_storage_key);
  }

  void updateIconsMap(Map<String, String> data) {
    _iconsMap.addAll(data);
  }

  Future<void> addAccount(Map acc) async {
    final pairs = _storage.keyPairs.val.toList();
    // remove duplicated account and add a new one
    pairs.retainWhere((e) => e['address'] != acc['address']);
    pairs.add(acc);
    _storage.keyPairs.val = pairs;

    setCurrentAddress(acc['address']);
  }

  Future<void> addContact(Map acc) async {
    final ls = _storage.contacts.val.toList();
    ls.add(acc);
    _storage.contacts.val = ls;

    if (acc['observation'] ?? false) {
      setCurrentAddress(acc['address']);
    }
  }

  Future<void> updateAccount(Map acc, {bool isExternal: false}) async {
    if (isExternal) {
      updateContact(acc);
    } else {
      _updateKeyPair(acc);
    }
  }

  Future<void> _updateKeyPair(Map acc) async {
    final List pairs = _storage.keyPairs.val.toList();
    pairs.removeWhere((e) => e['address'] == acc['address']);
    pairs.add(acc);
    _storage.keyPairs.val = pairs;
  }

  Future<void> updateContact(Map acc) async {
    final ls = _storage.contacts.val.toList();
    ls.removeWhere((e) => e['address'] == acc['address']);
    ls.add(acc);
    _storage.contacts.val = ls;
  }

  Future<void> deleteAccount(String? address) async {
    _deleteKeyPair(address);

    final mnemonics = Map.of(_storage.encryptedMnemonics.val);
    mnemonics.remove(address);
    _storage.encryptedMnemonics.val = mnemonics;
    final privateKeys = Map.of(_storage.encryptedPrivateKeys.val);
    privateKeys.remove(address);
    _storage.encryptedPrivateKeys.val = privateKeys;
  }

  Future<void> _deleteKeyPair(String? address) async {
    final List pairs = _storage.keyPairs.val.toList();
    pairs.removeWhere((e) => e['address'] == address);
    _storage.keyPairs.val = pairs;

    if (pairs.length > 0) {
      setCurrentAddress(pairs[0]['address']);
    } else if (externals.length > 0) {
      setCurrentAddress(externals[0]['address']);
    } else {
      setCurrentAddress('');
    }
  }

  Future<void> deleteContact(String address) async {
    final ls = _storage.contacts.val.toList();
    ls.removeWhere((e) => e['address'] == address);
    _storage.contacts.val = ls;
  }

  Future<void> encryptSeedAndSave(
      String? address, seed, seedType, password) async {
    final String key = Encrypt.passwordToEncryptKey(password);
    final encrypted = await FlutterAesEcbPkcs5.encryptString(seed, key);

    if (seedType == EVMKeyType.mnemonic.toString().split('.')[1]) {
      final mnemonics = Map.from(_storage.encryptedMnemonics.val);
      mnemonics.addAll({address: encrypted});
      _storage.encryptedMnemonics.val = mnemonics;
      return;
    }
    if (seedType == EVMKeyType.privateKey.toString().split('.')[1]) {
      final seeds = Map.from(_storage.encryptedPrivateKeys.val);
      seeds.addAll({address: encrypted});
      _storage.encryptedPrivateKeys.val = seeds;
    }
  }

  Future<void> updateEncryptedSeed(String? address, passOld, passNew) async {
    final seed = await getDecryptedSeed(address, passOld);
    if (seed != null) {
      encryptSeedAndSave(address, seed['seed'], seed['type'], passNew);
    }
  }

  Future<Map<String, dynamic>?> getDecryptedSeed(
      String? address, password) async {
    final key = Encrypt.passwordToEncryptKey(password);
    final mnemonic = _storage.encryptedMnemonics.val[address];
    if (mnemonic != null) {
      final Map<String, dynamic> res = {
        'type': EVMKeyType.mnemonic.toString().split('.')[1]
      };
      try {
        res['seed'] = await FlutterAesEcbPkcs5.decryptString(mnemonic, key);
      } catch (err) {
        print(err);
      }
      return res;
    }
    final privateKey = _storage.encryptedPrivateKeys.val[address];
    if (privateKey != null) {
      final Map<String, dynamic> res = {
        'type': EVMKeyType.privateKey.toString().split('.')[1]
      };
      try {
        res['seed'] = await FlutterAesEcbPkcs5.decryptString(privateKey, key);
      } catch (err) {
        print(err);
      }
      return res;
    }
    return null;
  }

  Future<bool> checkSeedExist(EVMKeyType keyType, String address) async {
    switch (keyType) {
      case EVMKeyType.mnemonic:
        return _storage.encryptedMnemonics.val[address] != null;
      case EVMKeyType.privateKey:
        return _storage.encryptedPrivateKeys.val[address] != null;
      default:
        return false;
    }
  }
}

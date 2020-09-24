import 'package:flutter_aes_ecb_pkcs5/flutter_aes_ecb_pkcs5.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/storage/localStorage.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/index.dart';
import 'package:polkawallet_sdk/utils/localStorage.dart';

/// A [Keyring] instance maintains the local storage
/// of key-pairs for users.
/// We need to pass the storage instance to [WalletSDK]'s
/// keyring api for account management.
class Keyring {
  final KeyringPrivateStore store = KeyringPrivateStore();

  int get ss58 => store.ss58;
  int setSS58(int ss58) {
    store.ss58 = ss58;
    return ss58;
  }

  List<KeyPairData> get keyPairs {
    return store.list.map((e) => KeyPairData.fromJson(e)).toList();
  }

  Future<void> init() async {
    await store.init();
  }
}

class KeyringPrivateStore {
  final KeyringStorage _storage = KeyringStorage();
  final LocalStorage _storageOld = LocalStorage();
  final List<int> ss58List = [0, 2, 42];

  Map<String, Map> _pubKeyAddressMap = {};

  int ss58 = 0;

  List get list {
    final ls = _storage.keyPairs.val.toList();
    ls.forEach((e) {
      final networkSS58 = ss58.toString();
      if (_pubKeyAddressMap[networkSS58] != null &&
          _pubKeyAddressMap[networkSS58][e['pubKey']] != null) {
        e['address'] = _pubKeyAddressMap[networkSS58][e['pubKey']];
      }
    });
    return ls;
  }

  /// the [GetStorage] package needs to be initiated before use.
  Future<void> init() async {
    await GetStorage.init(sdk_storage_key);
    await _loadKeyPairsFromStorage();
  }

  /// load keyPairs form local storage to memory.
  Future<void> _loadKeyPairsFromStorage() async {
    final ls = await _storageOld.getAccountList();
    if (ls.length > 0) {
      ls.retainWhere((e) {
        // delete all storageOld data
        _storageOld.removeAccount(e['pubKey']);
        if (e['mnemonic'] != null || e['rawSeed'] != null) {
          e.remove('mnemonic');
          e.remove('rawSeed');
        }

        // retain accounts from storageOld
        final i = _storage.keyPairs.val.indexWhere((pair) {
          return pair['pubKey'] == e['pubKey'];
        });
        return i < 0;
      });
      final List pairs = _storage.keyPairs.val.toList();
      pairs.add(ls);
      _storage.keyPairs.val = pairs;

      // and move all encrypted seeds to new storage
      _migrateSeeds();
    }
  }

  void updatePubKeyAddressMap(Map<String, Map> data) {
    _pubKeyAddressMap = data;
  }

  Future<void> addAccount(Map acc) async {
    final List pairs = _storage.keyPairs.val.toList();
    pairs.add(acc);
    _storage.keyPairs.val = pairs;
  }

  Future<void> updateAccount(Map acc) async {
    final List pairs = _storage.keyPairs.val.toList();
    pairs.removeWhere((e) => e['pubKey'] == acc['pubKey']);
    pairs.add(acc);
    _storage.keyPairs.val = pairs;
  }

  Future<void> deleteAccount(String pubKey) async {
    final List pairs = _storage.keyPairs.val.toList();
    pairs.removeWhere((e) => e['pubKey'] == pubKey);
    _storage.keyPairs.val = pairs;

    final mnemonics = Map.of(_storage.encryptedMnemonics.val);
    mnemonics.removeWhere((key, _) => key == pubKey);
    _storage.encryptedMnemonics.val = mnemonics;
    final seeds = Map.of(_storage.encryptedRawSeeds.val);
    seeds.removeWhere((key, _) => key == pubKey);
    _storage.encryptedRawSeeds.val = seeds;
  }

  Future<void> encryptSeedAndSave(
      String pubKey, seed, seedType, password) async {
    final String key = Encrypt.passwordToEncryptKey(password);
    final String encrypted = await FlutterAesEcbPkcs5.encryptString(seed, key);

    // read old data from storage-old
    final Map stored = await _storageOld.getSeeds(seedType);
    stored[pubKey] = encrypted;
    // and save to new storage
    if (seedType == KeyType.mnemonic.toString().split('.')[1]) {
      final mnemonics = Map.from(_storage.encryptedMnemonics.val);
      mnemonics.addAll(stored);
      _storage.encryptedMnemonics.val = mnemonics;
      return;
    }
    if (seedType == KeyType.rawSeed.toString().split('.')[1]) {
      final seeds = Map.from(_storage.encryptedRawSeeds.val);
      seeds.addAll(stored);
      _storage.encryptedRawSeeds.val = seeds;
    }
  }

  Future<void> updateEncryptedSeed(String pubKey, passOld, passNew) async {
    final seed = await getDecryptedSeed(pubKey, passOld);
    encryptSeedAndSave(pubKey, seed['seed'], seed['type'], passNew);
  }

  Future<Map<String, dynamic>> getDecryptedSeed(String pubKey, password) async {
    final key = Encrypt.passwordToEncryptKey(password);
    final mnemonic = _storage.encryptedMnemonics.val[pubKey];
    if (mnemonic != null) {
      final res = {'type': KeyType.mnemonic.toString().split('.')[1]};
      try {
        res['seed'] = await FlutterAesEcbPkcs5.decryptString(mnemonic, key);
      } catch (err) {
        print(err);
      }
      return res;
    }
    final rawSeed = _storage.encryptedRawSeeds.val[pubKey];
    if (rawSeed != null) {
      final res = {'type': KeyType.rawSeed.toString().split('.')[1]};
      try {
        res['seed'] = await FlutterAesEcbPkcs5.decryptString(rawSeed, key);
      } catch (err) {
        print(err);
      }
      return res;
    }
    return null;
  }

  Future<void> _migrateSeeds() async {
    final res = await Future.wait([
      _storageOld.getSeeds('mnemonic'),
      _storageOld.getSeeds('rawSeed'),
    ]);
    if (res[0].keys.length > 0) {
      final mnemonics = Map.of(_storage.encryptedMnemonics.val);
      mnemonics.addAll(res[0]);
      _storage.encryptedMnemonics.val = mnemonics;
      _storageOld.setSeeds('mnemonic', {});
    }
    if (res[1].keys.length > 0) {
      final seeds = Map.of(_storage.encryptedRawSeeds.val);
      seeds.addAll(res[1]);
      _storage.encryptedRawSeeds.val = seeds;
      _storageOld.setSeeds('rawSeed', {});
    }
  }
}

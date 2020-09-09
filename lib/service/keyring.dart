import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_aes_ecb_pkcs5/flutter_aes_ecb_pkcs5.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/service/index.dart';
import 'package:polkawallet_sdk/utils/index.dart';

class ServiceKeyring {
  ServiceKeyring(this.serviceRoot);

  final SubstrateService serviceRoot;

  Map<String, String> _pubKeyAddressMap = {};

  List get list {
    final ls = serviceRoot.storage.keyPairs.val.toList();
    ls.forEach((e) {
      if (_pubKeyAddressMap[e['pubKey']] != null) {
        e['address'] = _pubKeyAddressMap[e['pubKey']];
      }
    });
    return ls;
  }

  Future<void> loadKeyPairsFromStorage() async {
    final ls = await serviceRoot.storageOld.getAccountList();
    if (ls.length > 0) {
      ls.retainWhere((e) {
        // delete all storageOld data
        serviceRoot.storageOld.removeAccount(e['pubKey']);
        if (e['mnemonic'] != null || e['rawSeed'] != null) {
          e.remove('mnemonic');
          e.remove('rawSeed');
        }

        // retain accounts from storageOld
        final i = serviceRoot.storage.keyPairs.val.indexWhere((pair) {
          return pair['pubKey'] == e['pubKey'];
        });
        return i < 0;
      });
      final List pairs = serviceRoot.storage.keyPairs.val.toList();
      pairs.add(ls);
      serviceRoot.storage.keyPairs.val = pairs;

      // and move all encrypted seeds to new storage
      _migrateSeeds();
    }
  }

  Future<void> _migrateSeeds() async {
    final res = await Future.wait([
      serviceRoot.storageOld.getSeeds('mnemonic'),
      serviceRoot.storageOld.getSeeds('rawSeed'),
    ]);
    if (res[0].keys.length > 0) {
      final mnemonics = Map.of(serviceRoot.storage.encryptedMnemonics.val);
      mnemonics.addAll(res[0]);
      serviceRoot.storage.encryptedMnemonics.val = mnemonics;
      serviceRoot.storageOld.setSeeds('mnemonic', {});
    }
    if (res[1].keys.length > 0) {
      final seeds = Map.of(serviceRoot.storage.encryptedRawSeeds.val);
      seeds.addAll(res[1]);
      serviceRoot.storage.encryptedRawSeeds.val = seeds;
      serviceRoot.storageOld.setSeeds('rawSeed', {});
    }
  }

  Future<void> updatePubKeyAddressMap() async {
    if (serviceRoot.connectedNode == null) return;

    final List<String> pubKeys =
        list.map((e) => e['pubKey'].toString()).toList();
    final Map res = await serviceRoot.account
        .encodeAddress(pubKeys, [serviceRoot.connectedNode.ss58]);
    if (res != null && res[serviceRoot.connectedNode.ss58] != null) {
      _pubKeyAddressMap =
          Map<String, String>.of(res[serviceRoot.connectedNode.ss58]);
    }
  }

  /// Generate a set of new mnemonic.
  Future<String> generateMnemonic() async {
    final Map<String, dynamic> acc =
        await serviceRoot.evalJavascript('account.gen()');
    return acc['mnemonic'];
  }

  /// Import account from mnemonic/rawSeed/keystore.
  /// param [cryptoType] can be `sr25519`(default) or `ed25519`.
  /// return [null] if import failed.
  Future<Map> importAccount({
    @required KeyType keyType,
    @required String key,
    @required name,
    @required password,
    CryptoType cryptoType = CryptoType.sr25519,
    String derivePath = '',
  }) async {
    // generate json from js-api
    final String type = keyType.toString().split('.')[1];
    final String crypto = cryptoType.toString().split('.')[1];
    String code =
        'account.recover("$type", "$crypto", \'$key$derivePath\', "$password")';
    code = code.replaceAll(RegExp(r'\t|\n|\r'), '');
    final Map<String, dynamic> acc = await serviceRoot.evalJavascript(code);
    if (acc == null || acc['error'] != null) {
      return null;
    }

    // add metadata to json
    updateKeyPairMetaData(acc, name);

    // save seed and remove it before add account
    if (keyType == KeyType.mnemonic || keyType == KeyType.rawSeed) {
      final String seed = acc[type];
      if (seed != null && seed.isNotEmpty) {
        _encryptSeedAndSave(acc['pubKey'], acc[type], type, password);
        acc.remove(type);
      }
    }

    // save keystore to storage
    final List pairs = serviceRoot.storage.keyPairs.val.toList();
    pairs.add(acc);
    serviceRoot.storage.keyPairs.val = pairs;

    await updatePubKeyAddressMap();

    return acc;
  }

  Map updateKeyPairMetaData(Map acc, String name) {
    acc['name'] = name;
    acc['meta']['name'] = name;
    if (acc['meta']['whenCreated'] == null) {
      acc['meta']['whenCreated'] = DateTime.now().millisecondsSinceEpoch;
    }
    acc['meta']['whenEdited'] = DateTime.now().millisecondsSinceEpoch;
    return acc;
  }

  Future<void> _encryptSeedAndSave(
      String pubKey, seed, seedType, password) async {
    final String key = Encrypt.passwordToEncryptKey(password);
    final String encrypted = await FlutterAesEcbPkcs5.encryptString(seed, key);

    // read old data from storage-old
    final Map stored = await serviceRoot.storageOld.getSeeds(seedType);
    stored[pubKey] = encrypted;
    // and save to new storage
    if (seedType == KeyType.mnemonic.toString().split('.')[1]) {
      final mnemonics = Map.from(serviceRoot.storage.encryptedMnemonics.val);
      mnemonics.addAll(stored);
      serviceRoot.storage.encryptedMnemonics.val = mnemonics;
      return;
    }
    if (seedType == KeyType.rawSeed.toString().split('.')[1]) {
      final seeds = Map.from(serviceRoot.storage.encryptedRawSeeds.val);
      seeds.addAll(stored);
      serviceRoot.storage.encryptedRawSeeds.val = seeds;
    }
  }

  Future<Map<String, dynamic>> getDecryptedSeed(String pubKey, password) async {
    final key = Encrypt.passwordToEncryptKey(password);
    final mnemonic = serviceRoot.storage.encryptedMnemonics.val[pubKey];
    if (mnemonic != null) {
      final res = {'type': KeyType.mnemonic.toString().split('.')[1]};
      try {
        res['seed'] = await FlutterAesEcbPkcs5.decryptString(mnemonic, key);
      } catch (err) {
        print(err);
      }
      return res;
    }
    final rawSeed = serviceRoot.storage.encryptedRawSeeds.val[pubKey];
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

  /// Delete account
  Future<void> deleteAccount(String pubKey) async {
    final List pairs = serviceRoot.storage.keyPairs.val.toList();
    pairs.removeWhere((e) => e['pubKey'] == pubKey);
    serviceRoot.storage.keyPairs.val = pairs;

    final mnemonics = Map.of(serviceRoot.storage.encryptedMnemonics.val);
    mnemonics.removeWhere((key, _) => key == pubKey);
    serviceRoot.storage.encryptedMnemonics.val = mnemonics;
    final seeds = Map.of(serviceRoot.storage.encryptedRawSeeds.val);
    seeds.removeWhere((key, _) => key == pubKey);
    serviceRoot.storage.encryptedRawSeeds.val = seeds;
  }

  /// Update account in storage
  Future<void> updateAccount(Map acc) async {
    final List pairs = serviceRoot.storage.keyPairs.val.toList();
    pairs.removeWhere((e) => e['pubKey'] == acc['pubKey']);
    pairs.add(acc);
    serviceRoot.storage.keyPairs.val = pairs;
  }

  /// check password of account
  Future<bool> checkPassword(String pubKey, pass) async {
    final res = await serviceRoot
        .evalJavascript('account.checkPassword("$pubKey", "$pass")');
    if (res == null) {
      return false;
    }
    return true;
  }

  /// change password of account
  Future<Map> changePassword(String pubKey, passOld, passNew) async {
    final res = await serviceRoot.evalJavascript(
        'account.changePassword("$pubKey", "$passOld", "$passNew")');
    if (res != null) {
      final seed = await getDecryptedSeed(pubKey, passOld);
      _encryptSeedAndSave(pubKey, seed['seed'], seed['type'], passNew);
    }
    return res;
  }

  Future<String> checkDerivePath(
      String seed, path, CryptoType cryptoType) async {
    final String crypto = cryptoType.toString().split('.')[1];
    String res = await serviceRoot
        .evalJavascript('account.checkDerivePath("$seed", "$path", "$crypto")');
    return res;
  }

//  Future<Map> parseQrCode(String data) async {
//    final res = await apiRoot.evalJavascript('account.parseQrCode("$data")');
//    print('rawData: $data');
//    return res;
//  }
//
//  Future<Map> signAsync(String password) async {
//    final res = await apiRoot.evalJavascript('account.signAsync("$password")');
//    return res;
//  }
//
//  Future<Map> makeQrCode(Map txInfo, List params, {String rawParam}) async {
//    String param = rawParam != null ? rawParam : jsonEncode(params);
//    final Map res = await apiRoot.evalJavascript(
//      'account.makeTx(${jsonEncode(txInfo)}, $param)',
//      allowRepeat: true,
//    );
//    return res;
//  }
//
//  Future<Map> addSignatureAndSend(
//    String signed,
//    Map txInfo,
//    String pageTile,
//    String notificationTitle,
//  ) async {
//    final String address = store.account.currentAddress;
//    final Map res = await apiRoot.evalJavascript(
//      'account.addSignatureAndSend("$address", "$signed")',
//      allowRepeat: true,
//    );
//
//    if (res['hash'] != null) {
//      String hash = res['hash'];
//      NotificationPlugin.showNotification(
//        int.parse(hash.substring(0, 6)),
//        notificationTitle,
//        '$pageTile - ${txInfo['module']}.${txInfo['call']}',
//      );
//    }
//    return res;
//  }

  Future<Map> signAsExtension(String password, Map args) async {
    final String call = args['msgType'] == 'pub(bytes.sign)'
        ? 'signBytesAsExtension'
        : 'signTxAsExtension';
    final res = await serviceRoot.evalJavascript(
      'account.$call("$password", ${jsonEncode(args['request'])})',
      allowRepeat: true,
    );
    return res;
  }
}

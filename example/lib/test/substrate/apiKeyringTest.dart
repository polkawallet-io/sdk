import 'dart:convert';

import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/consts/settings.dart';
import 'package:polkawallet_sdk/api/types/addressIconData.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';

class ApiKeyringTest {
  static var _testKeystore =
      '{"pubKey":"0xcc597bd2e7eda5094d6aa462523b629a502db6cc71a6ae0e9b158d9e42c6c462","mnemonic":"welcome clinic duck mom connect heart poet admit vendor robot group vacuum","rawSeed":"","address":"15cwMLiH57HvrqBfMYpt5AgGrb5SAUKx7XQUcHnBSs2DAsGt","encoded":"taoH2SolrO8UhraK1JxuNW9AcMMPY5UXMTJjlcpuyEEAgAAAAQAAAAgAAADdvrSwzB9yIFQ7ZCHQoQQV93zLhlAiZlits1CX2hFNm3/zPjYW63U7NzoF76UU4hUvyUTmrvT/K37v0zQ1eFrXwXvc2fmKFJ17qSR2oDvHfuCb+ruCsSrx/UsGtNLbzyCiomVYGMvRh/EzHEfBQO4jGaDi4Sq5++8QE2vuDUTePF8WsVSb5L9N30SFuNQ1YiTH7XBRG9zQhQTofLl0","encoding":{"content":["pkcs8","sr25519"],"type":["scrypt","xsalsa20-poly1305"],"version":"3"},"meta":{}}';

  static WalletSDK sdk;
  static Keyring keyring;

  static Future<void> runApiKeyringTest(
      WalletSDK walletSDK, Keyring key) async {
    keyring = key;
    sdk = walletSDK;
    print("run ApiKeyringTest");
    await _test();
    print("ApiKeyringTest finish");
  }

  static Future<void> _test() async {
    print("generate mnemonic");
    AddressIconDataWithMnemonic generatedata =
        await sdk.api.keyring.generateMnemonic(network_ss58_map['polkadot']);
    assert(generatedata.mnemonic.split(' ').length == 12);
    assert(generatedata.svg != null);

    print("import account from mnemonic");
    var password = "a111111";
    var name = "a111111";
    var acc = await sdk.api.keyring.importAccount(keyring,
        keyType: KeyType.mnemonic,
        key: generatedata.mnemonic,
        name: name,
        password: password);
    assert(acc["mnemonic"] == generatedata.mnemonic);

    print("add account mnemonic");
    await sdk.api.keyring.addAccount(keyring,
        keyType: KeyType.mnemonic, acc: acc, password: password);
    assert(keyring.current != null);
    assert(keyring.current.icon != null);
    assert(keyring.current.address != null);

    AddressIconDataWithMnemonic generateDataNew = await sdk.api.keyring
        .generateMnemonic(network_ss58_map['polkadot'],
            key: generatedata.mnemonic);
    assert(generateDataNew.mnemonic == generatedata.mnemonic);
    assert(generateDataNew.svg != null);

    print("address from mnemonic");
    AddressIconData addressIconData = await sdk.api.keyring.addressFromMnemonic(
        network_ss58_map['polkadot'],
        mnemonic: generatedata.mnemonic);
    assert(generatedata.svg != null);

    print("address from KeyStore");
    dynamic dynamicData = await sdk.api.keyring.addressFromKeyStore(
        network_ss58_map['polkadot'],
        keyStore: jsonDecode(_testKeystore));
    assert(dynamicData != null && dynamicData[0] != null);

    print("import account from keystore");
    acc = await sdk.api.keyring.importAccount(keyring,
        keyType: KeyType.keystore,
        key: jsonEncode(jsonDecode(_testKeystore)),
        name: name,
        password: password);
    assert(acc != null);

    print("add account keystore");
    await sdk.api.keyring.addAccount(keyring,
        keyType: KeyType.keystore, acc: acc, password: password);
    assert(keyring.current != null);
    assert(keyring.current.icon != null);
    assert(keyring.current.address != null);

    print("address from RawSeed");
    addressIconData = await sdk.api.keyring
        .addressFromRawSeed(network_ss58_map['polkadot'], rawSeed: "Alice");
    assert(generatedata.svg != null);

    print("import account from rawSeed");
    acc = await sdk.api.keyring.importAccount(keyring,
        keyType: KeyType.rawSeed, key: "Alice", name: name, password: password);
    assert(acc != null);

    print("add account rawSeed");
    await sdk.api.keyring.addAccount(keyring,
        keyType: KeyType.rawSeed, acc: acc, password: password);
    assert(keyring.current != null);

    print("check password");
    assert(await sdk.api.keyring.checkPassword(keyring.current, password));

    print("check DerivePath");
    assert(await sdk.api.keyring
            .checkDerivePath("Alice", "", CryptoType.sr25519) ==
        null);

    print("change password");
    var passNew = "c111111";
    KeyPairData newData =
        await sdk.api.keyring.changePassword(keyring, password, passNew);
    assert(!await sdk.api.keyring.checkPassword(newData, password));
    assert(await sdk.api.keyring.checkPassword(newData, passNew));

    print("change name");
    var nameNew = "c111111";
    newData = await sdk.api.keyring.changeName(keyring, nameNew);
    assert(newData.name != name);
    assert(newData.name == nameNew);

    print("sign message / verify signature");
    var message = "Hello world, my tests.";
    final params = SignAsExtensionParam();
    params.msgType = "pub(bytes.sign)";
    params.request = {
      "address": keyring.current.address,
      "data": message,
    };
    ExtensionSignResult result =
        await sdk.api.keyring.signAsExtension(passNew, params);
    assert(result.signature != null);
    var verifySign = await sdk.api.keyring
        .signatureVerify(message, result.signature, keyring.current.address);
    assert(verifySign != null);
    assert(verifySign.isValid);

    // AddAccount contains
    // print("update PubKey Icons Map");
    // await sdk.api.keyring.updatePubKeyIconsMap(keyring);
    // assert(keyring.current.icon != null);

    // print("update PubKey Address Map");
    // await sdk.api.keyring.updatePubKeyAddressMap(keyring);
    // assert(keyring.current.address != null);

    // print("update PubKey Indices Map");
    // await sdk.api.keyring.updateIndicesMap(keyring);
    // assert(keyring.current.indexInfo != null);

    print("get Decrypted Seed");
    var seed = await sdk.api.keyring.getDecryptedSeed(keyring, passNew);
    assert(seed != null);
    assert(seed.error == null);

    print("add Contact");
    assert(await sdk.api.keyring.addContact(keyring, acc) != null);

    print("delete Account");
    await sdk.api.keyring.deleteAccount(keyring, newData);
    assert(keyring.current.address != newData.address);
  }
}

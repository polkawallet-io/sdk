import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/storage/types/GenerateMnemonicData.dart';
import 'package:polkawallet_sdk/api/apiETHKeyring.dart';
import 'package:polkawallet_sdk/storage/keyringETH.dart';
import 'package:polkawallet_sdk/storage/types/keyPairETHData.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';

class ApiEthKeyringTest {
  static String _testMnemonicETH =
      "clown trash dish duty expire select announce nothing winner pepper scorpion until";
  static String _testAddressETH = "0x634DbE93A30148aF3eB54E92a8Ebfb852D1Be50B";
  static String _testPKeyETH =
      "0xac2920c6d04d70f70aaaa541f61e2efaaa89a791e95e62505daa7b67593d87b1";
  static String _derivePath1 = "m/44'/60'/0'/0/1";
  static String _testAddress1ETH = "0x015d775B11761d78637801E1f166019Ca147B5BE";
  static String _testPKey1ETH =
      "0x5caf995633bac90804739bd0410ca151e397a8c03af364446d58af7a55d11040";

  static WalletSDK sdk;
  static KeyringETH keyringEth;

  static Future<void> runApiEthKeyringTest(
      WalletSDK walletSDK, KeyringETH keyring) async {
    keyringEth = keyring;
    sdk = walletSDK;
    print("run ApiEthKeyringTest");
    await _generateMnemonicTest();
    await _addressFromMnemonic();
    await _addressFromPrivateKey();
    await _account();
    print("ApiEthKeyringTest finish");
  }

  static Future<void> _generateMnemonicTest() async {
    print("generate mnemonic");
    GenerateMnemonicData data =
        await sdk.api.ethKeyring.generateMnemonic(mnemonic: _testMnemonicETH);
    assert(data.address == _testAddressETH);

    data = await sdk.api.ethKeyring
        .generateMnemonic(mnemonic: _testMnemonicETH, index: 1);
    assert(data.address == _testAddress1ETH);
  }

  static Future<void> _addressFromMnemonic() async {
    print("address from mnemonic");
    GenerateMnemonicData data = await sdk.api.ethKeyring
        .addressFromMnemonic(mnemonic: _testMnemonicETH, derivePath: "");
    assert(data.address == _testAddressETH);

    data = await sdk.api.ethKeyring.addressFromMnemonic(
        mnemonic: _testMnemonicETH, derivePath: _derivePath1);
    assert(data.address == _testAddress1ETH);
  }

  static Future<void> _addressFromPrivateKey() async {
    print("address from PrivateKey");
    GenerateMnemonicData data = await sdk.api.ethKeyring
        .addressFromPrivateKey(privateKey: _testPKeyETH);
    assert(data.address == _testAddressETH);

    data = await sdk.api.ethKeyring
        .addressFromPrivateKey(privateKey: _testPKey1ETH);
    assert(data.address == _testAddress1ETH);
  }

  static Future<void> _account() async {
    print("import account from mnemonic");
    var password = "a111111";
    var name = "a111111";
    var acc = await sdk.api.ethKeyring.importAccount(
        keyType: ETH_KeyType.mnemonic,
        key: _testMnemonicETH,
        derivePath: "",
        name: name,
        password: password);
    assert(acc["address"] == _testAddressETH);
    assert(acc["mnemonic"] == _testMnemonicETH);

    acc = await sdk.api.ethKeyring.importAccount(
        keyType: ETH_KeyType.mnemonic,
        key: _testMnemonicETH,
        derivePath: _derivePath1,
        name: name,
        password: password);
    assert(acc["address"] == _testAddress1ETH);
    assert(acc["mnemonic"] == _testMnemonicETH);

    print("add account mnemonic");
    KeyPairETHData data = await sdk.api.ethKeyring.addAccount(keyringEth,
        keyType: ETH_KeyType.mnemonic, acc: acc, password: password);

    print("import account from privateKey");
    acc = await sdk.api.ethKeyring.importAccount(
        keyType: ETH_KeyType.privateKey,
        key: _testPKeyETH,
        derivePath: "",
        name: name,
        password: password);
    assert(acc["privateKey"] == _testPKeyETH);
    assert(acc["address"] == _testAddressETH);

    acc = await sdk.api.ethKeyring.importAccount(
        keyType: ETH_KeyType.privateKey,
        key: _testPKey1ETH,
        derivePath: _derivePath1,
        name: name,
        password: password);
    assert(acc["privateKey"] == _testPKey1ETH);
    assert(acc["address"] == _testAddress1ETH);

    print("add account privateKey");
    data = await sdk.api.ethKeyring.addAccount(keyringEth,
        keyType: ETH_KeyType.privateKey, acc: acc, password: password);

    print("import account from keystore");

    acc = await sdk.api.ethKeyring.importAccount(
        keyType: ETH_KeyType.keystore,
        key: data.keystore,
        derivePath: "",
        name: name,
        password: password);
    assert(acc["address"] == _testAddress1ETH);

    print("check password");
    assert(await sdk.api.ethKeyring
        .checkPassword(keystore: data.keystore, pass: password));

    print("add account keystore");
    data = await sdk.api.ethKeyring.addAccount(keyringEth,
        keyType: ETH_KeyType.keystore, acc: acc, password: password);

    print("change password");
    var passNew = "c111111";
    KeyPairETHData newData = await sdk.api.ethKeyring.changePassword(
        keyring: keyringEth, passOld: password, passNew: passNew);
    assert(data.address == newData.address);
    assert(!await sdk.api.ethKeyring
        .checkPassword(keystore: newData.keystore, pass: password));
    assert(await sdk.api.ethKeyring
        .checkPassword(keystore: newData.keystore, pass: passNew));

    print("change name");
    var nameNew = "c111111";
    newData = await sdk.api.ethKeyring.changeName(keyringEth, nameNew);
    assert(data.address == newData.address);
    assert(newData.name != name);
    assert(newData.name == nameNew);

    print("sign message / verify signature");
    var message = "Hello world, my tests.";
    ExtensionSignResult result = await sdk.api.ethKeyring
        .signMessage(passNew, message, newData.keystore);
    assert(result.signature != null);
    var verifySign =
        await sdk.api.ethKeyring.signatureVerify(message, result.signature);
    assert(verifySign != null);
    assert(verifySign["signer"] == newData.address);

    print("update Address Icons Map");
    await sdk.api.ethKeyring.updateAddressIconsMap(keyringEth);
    assert(keyringEth.current.icon != null);

    print("get Decrypted Seed");
    var seed = await sdk.api.ethKeyring.getDecryptedSeed(keyringEth, passNew);
    assert(seed != null);
    assert(seed.error == null);

    print("add Contact");
    KeyPairETHData contackData =
        await sdk.api.ethKeyring.addContact(keyringEth, acc);
    assert(contackData != null);

    print("delete Account");
    await sdk.api.ethKeyring.deleteAccount(keyringEth, newData);
    assert(keyringEth.current.address != newData.address);
  }
}

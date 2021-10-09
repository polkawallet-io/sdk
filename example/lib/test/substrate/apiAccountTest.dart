import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/consts/settings.dart';

class ApiAccountTest {
  static Future<void> runApiAccountTest(WalletSDK sdk, Keyring keyring) async {
    print("run ApiAccountTest");

    print("encode address");
    var data = await sdk.api.account.encodeAddress([keyring.current.pubKey]);
    assert(data != null);

    print("decode address");
    data = await sdk.api.account.decodeAddress([keyring.current.address]);
    assert(data != null);

    print("check address format");
    assert(await sdk.api.account.checkAddressFormat(
        keyring.current.address, network_ss58_map['polkadot']));

    print("query balance");
    assert(await sdk.api.account.queryBalance(keyring.current.address) != null);

    print("query index info");
    assert((await sdk.api.account.queryIndexInfo([keyring.current.address]))
            .length >
        0);

    print("get PubKey Icons");
    assert((await sdk.api.account.getPubKeyIcons([keyring.current.pubKey]))
            .length >
        0);

    print("get Address Icons");
    assert((await sdk.api.account.getAddressIcons([keyring.current.address]))
            .length >
        0);

    print("ApiAccountTest finish");
  }
}

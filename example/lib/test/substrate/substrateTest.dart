import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk_example/test/substrate/apiAccountTest.dart';
import 'package:polkawallet_sdk_example/test/substrate/apiSettingTest.dart';

import 'apiKeyringTest.dart';

class SubstrateTest {
  static Future<void> runSubstrateTest(WalletSDK walletSDK, Keyring key) async {
    print("runSubstrateTest");
    await ApiKeyringTest.runApiKeyringTest(walletSDK, key);
    await ApiAccountTest.runApiAccountTest(walletSDK, key);
    await ApiSettingTest.runApiSettingTest(walletSDK);
    print("runSubstrateTest finish");
  }
}

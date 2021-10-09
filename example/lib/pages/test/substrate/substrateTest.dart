import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

import 'apiKeyringTest.dart';

class SubstrateTest {
  static Future<void> runSubstrateTest(WalletSDK walletSDK, Keyring key) async {
    print("runSubstrateTest");
    await ApiKeyringTest.runApiKeyringTest(walletSDK, key);
    print("runSubstrateTest finish");
  }
}

import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/storage/keyringETH.dart';
import 'package:polkawallet_sdk_example/pages/test/Etherem/apiEthKeyringTest.dart';

class EthTest {
  static Future<void> runEthTest(
      WalletSDK walletSDK, KeyringETH keyring) async {
    print("runEthTest");
    await ApiEthKeyringTest.runApiEthKeyringTest(walletSDK, keyring);
    print("runEthTest finish");
  }
}

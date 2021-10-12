import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

class ApiSettingTest {
  static Future<void> runApiSettingTest(WalletSDK sdk) async {
    print("run ApiSettingTest");

    print("query network const");
    assert((await sdk.api.setting.queryNetworkConst()) != null);

    print("query network props");
    assert((await sdk.api.setting.queryNetworkProps()) != null);

    print("ApiSettingTest finish");
  }
}

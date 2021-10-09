import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/keyringETH.dart';

import 'etherem/ethTest.dart';
import 'substrate/substrateTest.dart';

class Test {
  static Future<void> runTest(
      WalletSDK walletSDK, Keyring key, KeyringETH keyringEth) async {
    await EthTest.runEthTest(walletSDK, keyringEth);
    await SubstrateTest.runSubstrateTest(walletSDK, key);
  }
}

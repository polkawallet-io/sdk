library polkawallet_sdk;

import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_sdk/service/api.dart';
import 'package:polkawallet_sdk/storage/localStorage.dart';

class WalletSDK {
  PolkawalletApi api;

  KeyringStorage storage;
  bool isReady = false;
  bool isConnected = false;

  /// param [jsCode] is customized js code of parachain,
  /// the api works without [jsCode] param in Kusama/Polkadot.
  Future<void> init([String jsCode]) async {
    await GetStorage.init();

    storage = KeyringStorage();

    api = PolkawalletApi(storage);
    api.init();

    isReady = true;
  }
}

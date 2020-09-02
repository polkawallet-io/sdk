library polkawallet_sdk;

import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/service/index.dart';

enum Network { kusama, polkadot, acala, laminar }

class WalletSDK {
  PolkawalletApi api;

  SubstrateService _service;

  bool isReady = false;

  /// param [jsCode] is customized js code of parachain,
  /// the api works without [jsCode] param in Kusama/Polkadot.
  Future<void> init([String jsCode]) async {
    await GetStorage.init();

    _service = SubstrateService();
    _service.init();

    api = PolkawalletApi(_service);
    api.init();

    isReady = true;
  }
}

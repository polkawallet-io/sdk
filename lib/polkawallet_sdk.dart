library polkawallet_sdk;

import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/service/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

/// SDK launch a hidden webView to run polkadot.js/api for interacting
/// with the substrate-based block-chain network.
class WalletSDK {
  PolkawalletApi api;

  SubstrateService _service;

  /// param [jsCode] is customized js code of parachain,
  /// the api works without [jsCode] param in Kusama/Polkadot.
  void init(Keyring keyring, [String jsCode]) {
    _service = SubstrateService();
    _service.init(keyring);

    api = PolkawalletApi(_service);
    api.init();
  }
}

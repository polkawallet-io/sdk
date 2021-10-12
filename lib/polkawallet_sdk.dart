library polkawallet_sdk;

import 'dart:async';

import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/service/index.dart';
import 'package:polkawallet_sdk/service/webViewRunner.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/keyringETH.dart';

/// SDK launchs a hidden webView to run polkadot.js/api for interacting
/// with the substrate-based block-chain network.
class WalletSDK {
  late PolkawalletApi api;

  late SubstrateService _service;

  /// webView instance, this is the only instance of FlutterWebViewPlugin
  /// in App, we need to get it and reuse in other sdk.
  WebViewRunner? get webView => _service.webView;

  /// param [jsCode] is customized js code of parachain,
  /// the api works without [jsCode] param in Kusama/Polkadot.
  Future<void> init(
    Keyring keyring, {
    KeyringETH? keyringETH,
    WebViewRunner? webView,
    String? jsCode,
    String? jsCodeEth,
    required PluginType pluginType,
  }) async {
    final c = Completer();

    if (keyringETH == null) {
      keyringETH = KeyringETH();
      await keyringETH.init();
    }
    _service = SubstrateService();
    await _service.init(
      // keyring,
      webViewParam: webView,
      jsCode: jsCode,
      jsCodeEth: jsCodeEth,
      pluginType: pluginType,
      onInitiated: () {
        // inject keyPairs after webView launched
        _service.keyring.injectKeyPairsToWebView(keyring);

        // and initiate pubKeyIconsMap
        api.keyring.updatePubKeyIconsMap(keyring);

        // and eth initiate addressIconsMap
        api.ethKeyring.updateAddressIconsMap(keyringETH!);

        if (!c.isCompleted) {
          c.complete();
        }
      },
    );

    api = PolkawalletApi(_service);
    return c.future;
  }
}

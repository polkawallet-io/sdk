library polkawallet_sdk;

import 'dart:async';

import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/service/index.dart';
import 'package:polkawallet_sdk/service/webViewRunner.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

/// SDK launchs a hidden webView to run polkadot.js/api for interacting
/// with the substrate-based block-chain network.
class WalletSDK {
  PolkawalletApi? api;

  SubstrateService? _service;

  /// webView instance, this is the only instance of FlutterWebViewPlugin
  /// in App, we need to get it and reuse in other sdk.
  WebViewRunner? get webView => _service!.webView;

  /// param [jsCode] is customized js code of parachain,
  /// the api works without [jsCode] param in Kusama/Polkadot.
  Future<void> init(
    Keyring keyring, {
    WebViewRunner? webView,
    String? jsCode,
  }) async {
    final c = Completer();

    _service = SubstrateService();
    await _service!.init(
      keyring,
      webViewParam: webView,
      jsCode: jsCode,
      onInitiated: () {
        // inject keyPairs after webView launched
        _service!.keyring!.injectKeyPairsToWebView(keyring);

        // and initiate pubKeyIconsMap
        api!.keyring.updatePubKeyIconsMap(keyring);

        if (!c.isCompleted) {
          c.complete();
        }
      },
    );

    api = PolkawalletApi(_service);
    api!.init();
    return c.future;
  }
}

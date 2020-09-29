import 'dart:async';

import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/homeNavItem.dart';
import 'package:polkawallet_sdk/service/webViewRunner.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

abstract class PolkawalletPlugin implements PolkawalletPluginBase {
  /// for plugin page route.
  Future<dynamic> routePushNamed(BuildContext context, String route,
      {Object arguments}) async {
    Navigator.of(context).pushNamed('$name/$route', arguments: arguments);
  }

  /// we don't really need this method, calling webView.launch
  /// more than once will cause some exception.
  /// We just pass a [webViewParam] instance to the sdk.init function,
  /// so the sdk knows how to deal with the webView.
  Future<void> dispose() async {
    // do nothing
  }
}

abstract class PolkawalletPluginBase {
  /// A plugin's name was used to routing to sub-pages in the plugin,
  /// so every plugin needs it's unique name.
  final name = 'kusama';

  /// A plugin has a [WalletSDK] instance for connecting to it's node.
  final WalletSDK sdk = WalletSDK();

  /// Each plugin has it's own primary color in Polkawallet App.
  MaterialColor get primaryColor => Colors.black;

  /// Plugin should define a list of node to connect
  /// for users of Polkawallet App.
  List<NetworkParams> get nodeList => List<NetworkParams>();

  /// The [navItems] getter returns a list of [HomeNavItem] which defines
  /// the [Widget] to be used in home page of polkawallet App.
  List<HomeNavItem> get navItems => List<HomeNavItem>();

  /// App will add plugin's pages with custom [routes].
  Map<String, WidgetBuilder> get routes => Map<String, WidgetBuilder>();

  /// init the plugin runtime & connect to nodes
  Future<NetworkParams> start(Keyring keyring, {WebViewRunner webView}) async {
    await sdk.init(keyring, webView: webView);
    final res = await sdk.api.connectNodeAll(keyring, []);
    return res;
  }
}

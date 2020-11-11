import 'dart:async';

import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/types/balanceData.dart';
import 'package:polkawallet_sdk/api/types/networkStateData.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/homeNavItem.dart';
import 'package:polkawallet_sdk/service/webViewRunner.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';

abstract class PolkawalletPlugin implements PolkawalletPluginBase {
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

  /// Plugin should retrieve [balances] from sdk
  /// for display in Assets page of Polkawallet App.
  final balances = BalancesStore();

  /// Plugin should retrieve [networkState] & [networkConst] while start
  NetworkStateData networkState = NetworkStateData();
  Map networkConst = {};

  /// The [navItems] getter returns a list of [HomeNavItem] which defines
  /// the [Widget] to be used in home page of polkawallet App.
  List<HomeNavItem> getNavItems(Keyring keyring) => List<HomeNavItem>();

  /// App will add plugin's pages with custom [routes].
  Map<String, WidgetBuilder> getRoutes(Keyring keyring) =>
      Map<String, WidgetBuilder>();

  /// This method will be called while App switched to your plugin.
  /// In this method, the plugin should do:
  /// 1. init the plugin runtime & connect to nodes.
  /// 2. retrieve network const & state.
  /// 3. subscribe balances & set balancesStore.
  /// 4. setup other plugin state if needed.
  Future<NetworkParams> start(Keyring keyring, {WebViewRunner webView}) async {
    await sdk.init(keyring, webView: webView);
    final res = await sdk.api.connectNode(keyring, []);
    networkConst = await sdk.api.setting.queryNetworkConst();
    networkState = await sdk.api.setting.queryNetworkProps();

    if (keyring.current != null) {
      sdk.api.account.subscribeBalance(keyring.current.address,
          (BalanceData data) {
        balances.setBalance(data);
      });
    }

    return res;
  }

  /// This method will be called while App user changes account.
  /// In this method, the plugin should do:
  /// 1. update balance subscription to update balancesStore.
  /// 2. update other user state of plugin if needed.
  void onChangeAccount(KeyPairData account) {
    sdk.api.account.unsubscribeBalance();
    sdk.api.account.subscribeBalance(account.address, (BalanceData data) {
      balances.setBalance(data);
    });
  }
}

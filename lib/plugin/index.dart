import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_sdk/api/types/balanceData.dart';
import 'package:polkawallet_sdk/api/types/networkStateData.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/homeNavItem.dart';
import 'package:polkawallet_sdk/service/webViewRunner.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';

const String sdk_cache_key = 'polka_wallet_sdk_cache';
const String net_state_cache_key = 'network_state';
const String net_const_cache_key = 'network_const';
const String balance_cache_key = 'balances';

abstract class PolkawalletPlugin implements PolkawalletPluginBase {
  /// A plugin has a [WalletSDK] instance for connecting to it's node.
  final WalletSDK sdk = WalletSDK();

  /// Plugin should retrieve [balances] from sdk
  /// for display in Assets page of Polkawallet App.
  final balances = BalancesStore();

  final recoveryEnabled = false;

  /// Plugin should retrieve [networkState] & [networkConst] while start
  NetworkStateData get networkState =>
      NetworkStateData.fromJson(Map<String, dynamic>.from(
          _cache.read(_getNetworkCacheKey(net_state_cache_key)) ?? {}));
  Map get networkConst =>
      _cache.read(_getNetworkCacheKey(net_const_cache_key)) ?? {};

  GetStorage get _cache => GetStorage(sdk_cache_key);
  String _getNetworkCacheKey(String key) => '${key}_${basic.name}';
  String _getBalanceCacheKey(String pubKey) =>
      '${balance_cache_key}_${basic.name}_$pubKey';

  Future<void> updateNetworkState() async {
    final state = await Future.wait([
      sdk.api.service.setting.queryNetworkConst(),
      sdk.api.service.setting.queryNetworkProps(),
    ]);
    _cache.write(_getNetworkCacheKey(net_const_cache_key), state[0]);
    _cache.write(_getNetworkCacheKey(net_state_cache_key), state[1]);
  }

  void updateBalances(KeyPairData acc, BalanceData data) {
    balances.setBalance(data);

    _cache.write(_getBalanceCacheKey(acc.pubKey), data.toJson());
  }

  void loadBalances(KeyPairData acc) {
    updateBalances(
      acc,
      BalanceData.fromJson(Map<String, dynamic>.from(
          _cache.read(_getBalanceCacheKey(acc.pubKey)) ?? {})),
    );
  }

  Future<void> beforeStart(Keyring keyring, {WebViewRunner webView}) async {
    await sdk.init(keyring, webView: webView, jsCode: await loadJSCode());
    await onWillStart(keyring);
  }

  /// This method will be called while App switched to your plugin.
  /// In this method, the plugin should do:
  /// 1. init the plugin runtime & connect to nodes.
  /// 2. retrieve network const & state.
  /// 3. subscribe balances & set balancesStore.
  /// 4. setup other plugin state if needed.
  Future<NetworkParams> start(Keyring keyring) async {
    final res = await sdk.api.connectNode(keyring, nodeList);
    keyring.setSS58(res.ss58);
    await updateNetworkState();

    if (keyring.current.address != null) {
      loadBalances(keyring.current);
      sdk.api.account.subscribeBalance(keyring.current.address,
          (BalanceData data) {
        updateBalances(keyring.current, data);
      });
    }

    onStarted(keyring);

    return res;
  }

  /// This method will be called while App user changes account.
  void changeAccount(KeyPairData account) {
    sdk.api.account.unsubscribeBalance();
    loadBalances(account);
    sdk.api.account.subscribeBalance(account.address, (BalanceData data) {
      updateBalances(account, data);
    });

    onAccountChanged(account);
  }

  /// This method will be called before plugin start
  Future<void> onWillStart(Keyring keyring) async => null;

  /// This method will be called after plugin started
  Future<void> onStarted(Keyring keyring) async => null;

  /// This method will be called while App user changes account.
  /// In this method, the plugin should do:
  /// 1. update balance subscription to update balancesStore.
  /// 2. update other user state of plugin if needed.
  Future<void> onAccountChanged(KeyPairData account) async => null;

  /// we don't really need this method, calling webView.launch
  /// more than once will cause some exception.
  /// We just pass a [webViewParam] instance to the sdk.init function,
  /// so the sdk knows how to deal with the webView.
  Future<void> dispose() async {
    // do nothing
  }
}

abstract class PolkawalletPluginBase {
  /// A plugin's basic info, including: name, primaryColor and icons.
  final basic = PluginBasicData(name: 'kusama', primaryColor: Colors.black);

  /// Plugin should define a list of node to connect
  /// for users of Polkawallet App.
  List<NetworkParams> get nodeList => List<NetworkParams>();

  /// Plugin should provide [tokenIcons]
  /// for display in Assets page of Polkawallet App.
  final Map<String, Widget> tokenIcons = {};

  /// The [getNavItems] method returns a list of [HomeNavItem] which defines
  /// the [Widget] to be used in home page of polkawallet App.
  List<HomeNavItem> getNavItems(BuildContext context, Keyring keyring) =>
      List<HomeNavItem>();

  /// App will add plugin's pages with custom [routes].
  Map<String, WidgetBuilder> getRoutes(Keyring keyring) =>
      Map<String, WidgetBuilder>();

  /// App will inject plugin's [jsCode] into webview to connect.
  Future<String> loadJSCode() => null;
}

class PluginBasicData {
  PluginBasicData({
    this.name,
    this.ss58,
    this.primaryColor,
    this.icon,
    this.iconDisabled,
    this.jsCodeVersion,
    this.jsCodeVersionMin,
    this.isTestNet = true,
  });
  final String name;
  final int ss58;
  final MaterialColor primaryColor;

  /// The icons will be displayed in network-select page
  /// in Polkawallet App.
  final Widget icon;
  final Widget iconDisabled;

  /// JavaScript code version of your plugin.
  ///
  /// - Polkawallet App will perform hot-update for the js code
  ///  of your plugin with it.
  /// - The App will not show plugin pages if the old version
  ///  lower than [jsCodeVersionMin].
  final int jsCodeVersion;
  final int jsCodeVersionMin;

  /// Your plugin is connected to a para-chain testNet by default.
  final bool isTestNet;
}

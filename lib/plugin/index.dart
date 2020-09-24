import 'package:flutter/cupertino.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/homeNavItem.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

abstract class PolkawalletPlugin {
  /// A plugin's name was used to routing to sub-pages in the plugin,
  /// so every plugin needs it's unique name.
  final name = 'kusama';

  /// A plugin has a [WalletSDK] instance for connecting to it's node.
  final WalletSDK sdk = WalletSDK();

  /// The [navItems] getter returns a list of [HomeNavItem] which defines
  /// the [Widget] to be used in home page of polkawallet App.
  List<HomeNavItem> get navItems => [];

  /// init the plugin runtime & connect to nodes
  Future<NetworkParams> start(Keyring keyring, {String network}) async {
    sdk.init(keyring);
    return sdk.api.connectNodeAll(keyring, []);
  }

  /// we don't really need this method, because the plugin runtime
  /// will be replaced while another plugin start.
  Future<void> dispose() async {
    // do nothing.
  }
}

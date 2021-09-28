import 'dart:async';

import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/eth/index.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/service/account.dart';
import 'package:polkawallet_sdk/service/assets.dart';
import 'package:polkawallet_sdk/service/gov.dart';
import 'package:polkawallet_sdk/service/keyring.dart';
import 'package:polkawallet_sdk/service/parachain.dart';
import 'package:polkawallet_sdk/service/recovery.dart';
import 'package:polkawallet_sdk/service/setting.dart';
import 'package:polkawallet_sdk/service/staking.dart';
import 'package:polkawallet_sdk/service/tx.dart';
import 'package:polkawallet_sdk/service/uos.dart';
import 'package:polkawallet_sdk/service/walletConnect.dart';
import 'package:polkawallet_sdk/service/webViewRunner.dart';
// import 'package:polkawallet_sdk/storage/keyring.dart';

/// The service calling JavaScript API of `polkadot-js/api` directly
/// through [WebViewRunner], providing APIs for [PolkawalletApi].
class SubstrateService {
  late ServiceKeyring keyring;
  late ServiceSetting setting;
  late ServiceAccount account;
  late ServiceTx tx;

  late ServiceStaking staking;
  late ServiceGov gov;
  late ServiceParachain parachain;
  late ServiceAssets assets;
  late ServiceUOS uos;
  late ServiceRecovery recovery;

  late ServiceWalletConnect walletConnect;

  late EthereumService eth;

  WebViewRunner? _web;

  WebViewRunner? get webView => _web;

  Future<void> init({
    WebViewRunner? webViewParam,
    Function? onInitiated,
    String? jsCode,
    required PluginType pluginType,
  }) async {
    keyring = ServiceKeyring(this);
    setting = ServiceSetting(this);
    account = ServiceAccount(this);
    tx = ServiceTx(this);
    staking = ServiceStaking(this);
    gov = ServiceGov(this);
    parachain = ServiceParachain(this);
    assets = ServiceAssets(this);
    uos = ServiceUOS(this);
    recovery = ServiceRecovery(this);

    walletConnect = ServiceWalletConnect(this);

    eth = EthereumService.init(this);

    _web = webViewParam ?? WebViewRunner();
    await _web!
        .launch(keyring, onInitiated, jsCode: jsCode, pluginType: pluginType);
  }
}

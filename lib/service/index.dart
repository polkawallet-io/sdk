import 'dart:async';

import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/service/account.dart';
import 'package:polkawallet_sdk/service/assets.dart';
import 'package:polkawallet_sdk/service/bridge.dart';
import 'package:polkawallet_sdk/service/eth/index.dart';
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
import 'package:polkawallet_sdk/storage/keyring.dart';

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
  late ServiceBridge bridge;
  late ServiceUOS uos;
  late ServiceRecovery recovery;

  late ServiceWalletConnect walletConnect;
  late ServiceEth eth;

  WebViewRunner? _web;

  WebViewRunner? get webView => _web;

  Future<void> init(
    Keyring keyringStorage, {
    WebViewRunner? webViewParam,
    Function? onInitiated,
    String? jsCode,
    Function? socketDisconnectedAction,
  }) async {
    keyring = ServiceKeyring(this);
    setting = ServiceSetting(this);
    account = ServiceAccount(this);
    tx = ServiceTx(this);
    staking = ServiceStaking(this);
    gov = ServiceGov(this);
    parachain = ServiceParachain(this);
    assets = ServiceAssets(this);
    bridge = ServiceBridge(this);
    uos = ServiceUOS(this);
    recovery = ServiceRecovery(this);

    walletConnect = ServiceWalletConnect(this);
    eth = ServiceEth(this);

    _web = webViewParam ?? WebViewRunner();
    await _web!.launch(keyring, keyringStorage, onInitiated,
        jsCode: jsCode, socketDisconnectedAction: socketDisconnectedAction);
  }
}

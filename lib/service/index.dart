import 'dart:async';

import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/service/account.dart';
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
  ServiceKeyring keyring;
  ServiceSetting setting;
  ServiceAccount account;
  ServiceTx tx;

  ServiceStaking staking;
  ServiceGov gov;
  ServiceParachain parachain;
  ServiceUOS uos;
  ServiceRecovery recovery;

  ServiceWalletConnect walletConnect;

  WebViewRunner _web;

  WebViewRunner get webView => _web;

  Future<void> init(
    Keyring keyringStorage, {
    WebViewRunner webViewParam,
    Function onInitiated,
    String jsCode,
  }) async {
    keyring = ServiceKeyring(this);
    setting = ServiceSetting(this);
    account = ServiceAccount(this);
    tx = ServiceTx(this);
    staking = ServiceStaking(this);
    gov = ServiceGov(this);
    parachain = ServiceParachain(this);
    uos = ServiceUOS(this);
    recovery = ServiceRecovery(this);

    walletConnect = ServiceWalletConnect(this);

    _web = webViewParam ?? WebViewRunner();
    await _web.launch(keyring, keyringStorage, onInitiated, jsCode: jsCode);
  }
}

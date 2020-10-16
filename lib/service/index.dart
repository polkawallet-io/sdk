import 'dart:async';
import 'package:polkawallet_sdk/service/account.dart';
import 'package:polkawallet_sdk/service/keyring.dart';
import 'package:polkawallet_sdk/service/recovery.dart';
import 'package:polkawallet_sdk/service/setting.dart';
import 'package:polkawallet_sdk/service/staking.dart';
import 'package:polkawallet_sdk/service/tx.dart';
import 'package:polkawallet_sdk/service/uos.dart';
import 'package:polkawallet_sdk/service/webViewRunner.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

class SubstrateService {
  ServiceKeyring keyring;
  ServiceSetting setting;
  ServiceAccount account;
  ServiceTx tx;

  ServiceStaking staking;
  ServiceUOS uos;
  ServiceRecovery recovery;

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
    uos = ServiceUOS(this);
    recovery = ServiceRecovery(this);

    _web = webViewParam ?? WebViewRunner();
    await _web.launch(keyring, keyringStorage, onInitiated, jsCode: jsCode);
  }
}

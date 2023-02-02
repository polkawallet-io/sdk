import 'dart:convert';

import 'package:polkawallet_sdk/api/apiAccount.dart';
import 'package:polkawallet_sdk/api/apiAssets.dart';
import 'package:polkawallet_sdk/api/apiBridge.dart';
import 'package:polkawallet_sdk/api/apiGov.dart';
import 'package:polkawallet_sdk/api/apiGov2.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/api/apiParachain.dart';
import 'package:polkawallet_sdk/api/apiRecovery.dart';
import 'package:polkawallet_sdk/api/apiSetting.dart';
import 'package:polkawallet_sdk/api/apiStaking.dart';
import 'package:polkawallet_sdk/api/apiTx.dart';
import 'package:polkawallet_sdk/api/apiWalletConnect.dart';
import 'package:polkawallet_sdk/api/eth/index.dart';
import 'package:polkawallet_sdk/api/subscan.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/service/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

/// The [PolkawalletApi] instance is the wrapper of `polkadot-js/api`.
/// It provides:
/// * [ApiKeyring] of npm package [@polkadot/keyring](https://www.npmjs.com/package/@polkadot/keyring)
/// * [ApiSetting], the [networkConst] and [networkProperties] of `polkadot-js/api`.
/// * [ApiAccount], for querying on-chain data of accounts, like balances or indices.
/// * [ApiTx], sign and send tx.
/// * [ApiStaking] and [ApiGov], the staking and governance module of substrate.
/// * [ApiGov2], the new referenda module of substrate.
/// * [ApiRecovery], the social-recovery module of Kusama network.
class PolkawalletApi {
  PolkawalletApi(this.service) {
    keyring = ApiKeyring(this, service.keyring);
    setting = ApiSetting(this, service.setting);
    account = ApiAccount(this, service.account);
    tx = ApiTx(this, service.tx);

    staking = ApiStaking(this, service.staking);
    gov = ApiGov(this, service.gov);
    gov2 = ApiGov2(this, service.gov2);
    parachain = ApiParachain(this, service.parachain);
    assets = ApiAssets(this, service.assets);
    bridge = ApiBridge(this, service.bridge);
    recovery = ApiRecovery(this, service.recovery);

    walletConnect = ApiWalletConnect(this, service.walletConnect);
    eth = ApiEth(this, service.eth);
  }

  final SubstrateService service;

  NetworkParams? _connectedNode;

  late ApiKeyring keyring;
  late ApiSetting setting;
  late ApiAccount account;
  late ApiTx tx;

  late ApiStaking staking;
  late ApiGov gov;
  late ApiGov2 gov2;
  late ApiParachain parachain;
  late ApiAssets assets;
  late ApiBridge bridge;
  late ApiRecovery recovery;

  late ApiWalletConnect walletConnect;
  late ApiEth eth;

  final SubScanApi subScan = SubScanApi();

  // void init() {
  //   keyring = ApiKeyring(this, service.keyring);
  //   setting = ApiSetting(this, service.setting);
  //   account = ApiAccount(this, service.account);
  //   tx = ApiTx(this, service.tx);

  //   staking = ApiStaking(this, service.staking);
  //   gov = ApiGov(this, service.gov);
  //   parachain = ApiParachain(this, service.parachain);
  //   assets = ApiAssets(this, service.assets);
  //   uos = ApiUOS(this, service.uos);
  //   recovery = ApiRecovery(this, service.recovery);

  //   walletConnect = ApiWalletConnect(this, service.walletConnect);
  // }

  NetworkParams? get connectedNode => _connectedNode;

  /// connect to a list of nodes, return null if connect failed.
  Future<NetworkParams?> connectNode(
      Keyring keyringStorage, List<NetworkParams> nodes) async {
    _connectedNode = null;
    final NetworkParams? res = await service.webView!.connectNode(nodes);
    if (res != null) {
      _connectedNode = res;

      // update indices of keyPairs after connect
      keyring.updateIndicesMap(keyringStorage);
    }
    return res;
  }

  Future<NetworkParams?> connectEVM(NetworkParams node) async {
    _connectedNode = null;
    final NetworkParams? res = await service.webView!.connectEVM(node);
    if (res != null) {
      _connectedNode = res;
    }
    return res;
  }

  /// subscribe message.
  Future<void> subscribeMessage(
    String jsCall,
    List params,
    String channel,
    Function callback,
  ) async {
    service.webView!.subscribeMessage(
      'settings.subscribeMessage($jsCall, ${jsonEncode(params)}, "$channel")',
      channel,
      callback,
    );
  }

  /// unsubscribe message.
  void unsubscribeMessage(String channel) {
    service.webView!.unsubscribeMessage(channel);
  }
}

import 'package:polkawallet_sdk/api/apiAccount.dart';
import 'package:polkawallet_sdk/api/apiGov.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/api/apiRecovery.dart';
import 'package:polkawallet_sdk/api/apiSetting.dart';
import 'package:polkawallet_sdk/api/apiStaking.dart';
import 'package:polkawallet_sdk/api/apiTx.dart';
import 'package:polkawallet_sdk/api/apiUOS.dart';
import 'package:polkawallet_sdk/api/subscan.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/service/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

class PolkawalletApi {
  PolkawalletApi(this.service);

  final SubstrateService service;

  NetworkParams _connectedNode;

  ApiKeyring keyring;
  ApiSetting setting;
  ApiAccount account;
  ApiTx tx;

  ApiStaking staking;
  ApiGov gov;
  ApiUOS uos;
  ApiRecovery recovery;

  final SubScanApi subScan = SubScanApi();

  void init() {
    keyring = ApiKeyring(this, service.keyring);
    setting = ApiSetting(this, service.setting);
    account = ApiAccount(this, service.account);
    tx = ApiTx(this, service.tx);

    staking = ApiStaking(this, service.staking);
    gov = ApiGov(this, service.gov);
    uos = ApiUOS(this, service.uos);
    recovery = ApiRecovery(this, service.recovery);
  }

  NetworkParams get connectedNode => _connectedNode;

  /// connect to a list of nodes, return null if connect failed.
  Future<NetworkParams> connectNode(
      Keyring keyringStorage, List<NetworkParams> nodes) async {
    _connectedNode = null;
    final NetworkParams res = await service.webView.connectNode(nodes);
    if (res != null) {
      _connectedNode = res;

      // update indices of keyPairs after connect
      keyring.updateIndicesMap(keyringStorage);
    }
    return res;
  }

  /// subscribe message.
  Future<void> subscribeMessage(
    String code,
    String channel,
    Function callback,
  ) async {
    service.webView.subscribeMessage(code, channel, callback);
  }

  /// unsubscribe message.
  void unsubscribeMessage(String channel) {
    service.webView.unsubscribeMessage(channel);
  }
}

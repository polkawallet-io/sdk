import 'package:polkawallet_sdk/api/apiAccount.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/api/apiSetting.dart';
import 'package:polkawallet_sdk/api/apiStaking.dart';
import 'package:polkawallet_sdk/api/apiTx.dart';
import 'package:polkawallet_sdk/api/apiUOS.dart';
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
  ApiUOS uos;

  void init() {
    keyring = ApiKeyring(service.keyring);
    setting = ApiSetting(this, service.setting);
    account = ApiAccount(this, service.account);
    tx = ApiTx(this, service.tx);

    staking = ApiStaking(this, service.staking);
    uos = ApiUOS(this, service.uos);
  }

  NetworkParams get connectedNode => _connectedNode;

  /// connect to a specific node, return null if connect failed.
  /// there is always only one webView instance in sdk,
  /// so to connect to a new node, we don't need to disconnect the exist one.
  Future<NetworkParams> connectNode(
      Keyring keyringStorage, NetworkParams params) async {
    _connectedNode = null;
    final String res = await service.webView.connectNode(params);

    // update pubKeyAddress map after node connected,
    // so we can have the correct address format
    if (res != null) {
      _connectedNode = params;
      return params;
    }
    return null;
  }

  /// connect to a list of nodes, return null if connect failed.
  Future<NetworkParams> connectNodeAll(
      Keyring keyringStorage, List<NetworkParams> nodes) async {
    _connectedNode = null;
    final NetworkParams res = await service.webView.connectNodeAll(nodes);

    // update pubKeyAddress map after node connected,
    // so we can have the correct address format
    if (res != null) {
      _connectedNode = res;
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

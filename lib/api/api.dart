import 'package:polkawallet_sdk/api/apiAccount.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/api/apiSetting.dart';
import 'package:polkawallet_sdk/api/apiTx.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/service/index.dart';

class PolkawalletApi {
  PolkawalletApi(this.service);

  final SubstrateService service;

  ApiKeyring keyring;
  ApiSetting setting;
  ApiAccount account;
  ApiTx tx;

  void init() {
    keyring = ApiKeyring(service.keyring);
    setting = ApiSetting(this, service.setting);
    account = ApiAccount(this, service.account);
    tx = ApiTx(this, service.tx);
  }

  bool get isConnected {
    return service.connectedNode != null;
  }

  NetworkParams get connectedNode => service.connectedNode;

  /// connect to a specific node, return null if connect failed.
  /// there is always only one webView instance in sdk,
  /// so to connect to a new node, we don't need to disconnect the exist one.
  Future<NetworkParams> connectNode(NetworkParams params) async {
    final String res = await service.connectNode(params);
    if (res != null) {
      return params;
    }
    return null;
  }

  /// connect to a list of nodes, return null if connect failed.
  Future<NetworkParams> connectNodeAll(List<NetworkParams> nodes) async {
    final NetworkParams res = await service.connectNodeAll(nodes);
    return res;
  }

  /// disconnect to node.
  Future<void> disconnect() async {
    await service.disconnect();
  }

//  Future<void> _checkJSCodeUpdate() async {
//    // check js code update
//    final network = store.settings.endpoint.info;
//    final jsVersion = await WalletApi.fetchPolkadotJSVersion(network);
//    final bool needUpdate =
//        await UI.checkJSCodeUpdate(context, jsVersion, network);
//    if (needUpdate) {
//      await UI.updateJSCode(context, jsStorage, network, jsVersion);
//    }
//  }

  /// subscribe message.
  Future<void> subscribeMessage(
    String code,
    String channel,
    Function callback,
  ) async {
    service.subscribeMessage(code, channel, callback);
  }

  /// unsubscribe message.
  Future<void> unsubscribeMessage(String channel) async {
    service.unsubscribeMessage(channel);
  }
}

import 'package:polkawallet_sdk/api/apiAccount.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/api/apiSetting.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/service/index.dart';

class PolkawalletApi {
  PolkawalletApi(this.service);

  final SubstrateService service;

  NetworkParams connectedNode;

  ApiKeyring keyring;
  ApiSetting setting;
  ApiAccount account;

  void init() {
    keyring = ApiKeyring(service.keyring);
    setting = ApiSetting(this, service.setting);
    account = ApiAccount(this, service.account);

//    DefaultAssetBundle.of(context)
//        .loadString('lib/js_as_extension/dist/main.js')
//        .then((String js) {
//      print('asExtensionJSCode loaded');
//      asExtensionJSCode = js;
//    });
  }

  bool get isConnected {
    return connectedNode != null;
  }

  /// connect to a specific node, return null if connect failed.
  Future<NetworkParams> connectNode(NetworkParams params) async {
    final String res = await service.connectNode(params.endpoint);
    if (res != null) {
      connectedNode = params;
      return params;
    }
    return null;
  }

  /// connect to a list of nodes, return null if connect failed.
  Future<NetworkParams> connectNodeAll(List<NetworkParams> nodes) async {
    final String res =
        await service.connectNodeAll(nodes.map((e) => e.endpoint).toList());
    if (res != null) {
      final node = nodes.firstWhere((e) => e.endpoint == res);
      connectedNode = node;
      return node;
    }
    return null;
  }

  /// disconnect to node.
  Future<void> disconnect() async {
    await service.disconnect();
    connectedNode = null;
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

//  Future<void> subscribeMessage(
//    String code,
//    String channel,
//    Function callback,
//  ) async {
//    _msgHandlers[channel] = callback;
//    evalJavascript(code, allowRepeat: true);
//  }
//
//  Future<void> unsubscribeMessage(String channel) async {
//    _web.evalJavascript('unsub$channel()');
//  }
}

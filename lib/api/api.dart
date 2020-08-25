import 'package:polkawallet_sdk/api/apiAccount.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/service/index.dart';

class PolkawalletApi {
  PolkawalletApi(this.service);

  final SubstrateService service;

  NetworkParams connectedNode;

  ApiAccount account;
  ApiKeyring keyring;

  void init() {
    account = ApiAccount(this, service.account);
    keyring = ApiKeyring(service.keyring);

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

//  Future<void> fetchNetworkProps() async {
//    // fetch network info
//    List<dynamic> info = await Future.wait([
//      evalJavascript('settings.getNetworkConst()'),
//      evalJavascript('api.rpc.system.properties()'),
//      evalJavascript('api.rpc.system.chain()'),
//    ]);
//    store.settings.setNetworkConst(info[0]);
//    store.settings.setNetworkState(info[1]);
//    store.settings.setNetworkName(info[2]);
//
//    // fetch account balance
//    if (store.account.accountListAll.length > 0) {
//      if (store.settings.endpoint.info == networkEndpointAcala.info ||
//          store.settings.endpoint.info == networkEndpointLaminar.info) {
//        laminar.subscribeTokenPrices();
//        await assets.fetchBalance();
//        return;
//      }
//
//      await Future.wait([
//        assets.fetchBalance(),
//        staking.fetchAccountStaking(),
//        account.fetchAccountsBonded(
//            store.account.accountList.map((i) => i.pubKey).toList()),
//      ]);
//    }
//
//    // fetch staking overview data as initializing
//    staking.fetchStakingOverview();
//  }

//  Future<void> subscribeBestNumber(Function callback) async {
//    final String channel = "BestNumber";
//    subscribeMessage(
//        'settings.subscribeMessage("chain", "bestNumber", [], "$channel")',
//        channel,
//        callback);
//  }
//
//  Future<void> unsubscribeBestNumber() async {
//    unsubscribeMessage('BestNumber');
//  }
//
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

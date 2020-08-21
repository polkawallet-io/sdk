import 'package:polkawallet_sdk/api/apiAccount.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/service/index.dart';

class PolkawalletApi {
  PolkawalletApi(this.service);

  final SubstrateService service;

  ApiAccount account;
  ApiKeyring keyring;

  void init() {
    account = ApiAccount(service.account);
    keyring = ApiKeyring(service.keyring);

//    DefaultAssetBundle.of(context)
//        .loadString('lib/js_as_extension/dist/main.js')
//        .then((String js) {
//      print('asExtensionJSCode loaded');
//      asExtensionJSCode = js;
//    });
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

//  Future<void> connectNode() async {
//    String node = store.settings.endpoint.value;
//    // do connect
//    String res = await evalJavascript('settings.connect("$node")');
//    if (res == null) {
//      print('connect failed');
//      store.settings.setNetworkName(null);
//      return;
//    }
//    fetchNetworkProps();
//  }
//
//  Future<void> connectNodeAll() async {
//    List<String> nodes =
//        store.settings.endpointList.map((e) => e.value).toList();
//    // do connect
//    String res =
//        await evalJavascript('settings.connectAll(${jsonEncode(nodes)})');
//    if (res == null) {
//      print('connect failed');
//      store.settings.setNetworkName(null);
//      return;
//    }
//    int index = store.settings.endpointList.indexWhere((i) => i.value == res);
//    if (index < 0) return;
//    store.settings.setEndpoint(store.settings.endpointList[index]);
//    fetchNetworkProps();
//  }
//
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

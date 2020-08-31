import 'dart:async';
import 'package:polkawallet_sdk/service/index.dart';

class ServiceSetting {
  ServiceSetting(this.serviceRoot);

  final SubstrateService serviceRoot;

  Future<Map> queryNetworkConst() async {
    final Map res =
        await serviceRoot.evalJavascript('settings.getNetworkConst()');
    return res;
  }

  Future<Map> queryNetworkProps() async {
    // fetch network info
    List<dynamic> res = await Future.wait([
      serviceRoot.evalJavascript('api.rpc.system.properties()'),
      serviceRoot.evalJavascript('api.rpc.system.chain()'),
    ]);

    if (res[0] == null || res[1] == null) {
      return null;
    }

    final Map props = res[0];
    props['name'] = res[1];
    return props;
  }

  Future<void> subscribeBestNumber(Function callback) async {
    final String channel = "BestNumber";
    serviceRoot.subscribeMessage(
        'settings.subscribeMessage("chain", "bestNumber", [], "$channel")',
        channel,
        callback);
  }

  Future<void> unsubscribeBestNumber() async {
    serviceRoot.unsubscribeMessage('BestNumber');
  }
}

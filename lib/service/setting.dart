import 'package:polkawallet_sdk/service/index.dart';

class ServiceSetting {
  ServiceSetting(this.serviceRoot);

  final SubstrateService serviceRoot;

  Future<Map> queryNetworkConst() async {
    final Map res = await serviceRoot.webView
        .evalJavascript('settings.getNetworkConst(api)');
    return res;
  }

  Future<Map> queryNetworkProps() async {
    // fetch network info
    List<dynamic> res = await Future.wait([
      serviceRoot.webView.evalJavascript('settings.getNetworkProperties(api)'),
      serviceRoot.webView.evalJavascript('api.rpc.system.chain()'),
    ]);

    if (res[0] == null || res[1] == null) {
      return null;
    }

    final Map props = res[0];
    props['name'] = res[1];
    return props;
  }
}

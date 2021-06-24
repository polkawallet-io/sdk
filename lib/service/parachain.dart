import 'package:polkawallet_sdk/service/index.dart';

class ServiceParachain {
  ServiceParachain(this.serviceRoot);

  final SubstrateService serviceRoot;

  Future<Map> queryAuctionWithWinners() async {
    final Map res = await serviceRoot.webView
        .evalJavascript('parachain.queryAuctionWithWinners(api)');
    return res;
  }

  Future<String> queryUserContributions(String paraId, String pubKey) async {
    final String res = await serviceRoot.webView.evalJavascript(
        'parachain.queryUserContributions(api, "$paraId", "$pubKey")');
    return res;
  }
}

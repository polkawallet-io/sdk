import 'package:polkawallet_sdk/service/index.dart';

class ServiceParachain {
  ServiceParachain(this.serviceRoot);

  final SubstrateService serviceRoot;

  Future<Map> queryAuctionWithWinners() async {
    final Map res = await serviceRoot.webView
        .evalJavascript('parachain.queryAuctionWithWinners(api)');
    return res;
  }

  Future<List<String>> queryUserContributions(
      List<String> paraIds, String pubKey) async {
    final res = await serviceRoot.webView.evalJavascript('Promise.all(['
        '${paraIds.map((e) => 'parachain.queryUserContributions(api, "$e", "$pubKey")').join(',')}])');
    return List<String>.from(res);
  }
}

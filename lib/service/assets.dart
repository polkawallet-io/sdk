import 'dart:async';

import 'package:polkawallet_sdk/service/index.dart';

class ServiceAssets {
  ServiceAssets(this.serviceRoot);

  final SubstrateService serviceRoot;

  Future<List?> getAssetsAll() async {
    final List? res =
        await (serviceRoot.webView!.evalJavascript('assets.getAssetsAll(api)')
            as FutureOr<List<dynamic>?>);
    return res;
  }

  Future<List?> queryAssetsBalances(List<String> ids, String address) async {
    final List? res = await (serviceRoot.webView!.evalJavascript('Promise.all(['
        '${ids.map((e) => 'api.query.assets.account($e, "$address")').join(',')}'
        '])') as FutureOr<List<dynamic>?>);
    return res;
  }
}

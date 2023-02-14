import 'dart:async';
import 'dart:convert';

import 'package:polkawallet_sdk/service/index.dart';

class ServiceGov2 {
  ServiceGov2(this.serviceRoot);

  final SubstrateService serviceRoot;

  Future<bool> checkGovExist(int version) async {
    final bool? res = await serviceRoot.webView!.evalJavascript(
        'gov2.checkGovExist(api, $version)',
        wrapPromise: false);
    return res ?? false;
  }

  Future<Map> queryReferendums(String address) async {
    final Map res = await serviceRoot.webView!
        .evalJavascript('gov2.queryReferendums(api, "$address")');
    return res;
  }

  Future<List?> getExternalLinks(Map params) async {
    final dynamic res = await serviceRoot.webView!
        .evalJavascript('settings.genLinks(api, ${jsonEncode(params)})');
    return res;
  }

  Future<List?> getReferendumVoteConvictions() async {
    final dynamic res = await serviceRoot.webView!
        .evalJavascript('gov2.getReferendumVoteConvictions(api)');
    return res;
  }
}

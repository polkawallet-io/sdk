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

  Future<List> queryReferendums() async {
    final dynamic data =
        await serviceRoot.webView!.evalJavascript('gov.queryReferendums(api)');
    if (data != null) {
      final List list = data['referendums'];
      list.asMap().forEach((k, v) {
        v['detail'] = data['details'][k];
      });
      return list;
    }
    return [];
  }

  Future<List?> getDemocracyUnlocks(String address) async {
    final dynamic res = await serviceRoot.webView!
        .evalJavascript('gov.getDemocracyUnlocks(api, "$address")');
    return res;
  }

  Future<List?> getExternalLinks(Map params) async {
    final dynamic res = await serviceRoot.webView!
        .evalJavascript('settings.genLinks(api, ${jsonEncode(params)})');
    return res;
  }

  Future<List?> getReferendumVoteConvictions() async {
    final dynamic res = await serviceRoot.webView!
        .evalJavascript('gov.getReferendumVoteConvictions(api)');
    return res;
  }
}

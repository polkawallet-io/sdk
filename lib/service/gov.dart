import 'dart:async';
import 'dart:convert';

import 'package:polkawallet_sdk/service/index.dart';

class ServiceGov {
  ServiceGov(this.serviceRoot);

  final SubstrateService serviceRoot;

  Future<List?> getDemocracyUnlocks(String address) async {
    final List? res = await (serviceRoot.webView!
            .evalJavascript('gov.getDemocracyUnlocks(api, "$address")')
        as FutureOr<List<dynamic>?>);
    return res;
  }

  Future<List?> getExternalLinks(Map params) async {
    final List? res = await (serviceRoot.webView!
            .evalJavascript('settings.genLinks(api, ${jsonEncode(params)})')
        as FutureOr<List<dynamic>?>);
    return res;
  }

  Future<List?> getReferendumVoteConvictions() async {
    final List? res = await (serviceRoot.webView!
            .evalJavascript('gov.getReferendumVoteConvictions(api)')
        as FutureOr<List<dynamic>?>);
    return res;
  }

  Future<List> queryReferendums(String address) async {
    final Map? data = await (serviceRoot.webView!
            .evalJavascript('gov.fetchReferendums(api, "$address")')
        as FutureOr<Map<dynamic, dynamic>?>);
    if (data != null) {
      final List list = data['referendums'];
      list.asMap().forEach((k, v) {
        v['detail'] = data['details'][k];
      });
      return list;
    }
    return [];
  }

  Future<List?> queryProposals() async {
    final List? data = await (serviceRoot.webView!
        .evalJavascript('gov.fetchProposals(api)') as FutureOr<List<dynamic>?>);
    return data;
  }

  Future<Map?> queryTreasuryProposal(String id) async {
    final Map? data = await (serviceRoot.webView!
            .evalJavascript('api.query.treasury.proposals($id)')
        as FutureOr<Map<dynamic, dynamic>?>);
    return data;
  }

  Future<Map?> queryCouncilVotes() async {
    final Map? votes =
        await (serviceRoot.webView!.evalJavascript('gov.fetchCouncilVotes(api)')
            as FutureOr<Map<dynamic, dynamic>?>);
    return votes;
  }

  Future<Map?> queryUserCouncilVote(String address) async {
    final Map? votes = await (serviceRoot.webView!
            .evalJavascript('api.derive.council.votesOf("$address")')
        as FutureOr<Map<dynamic, dynamic>?>);
    return votes;
  }

  Future<Map?> queryCouncilInfo() async {
    final Map? info = await (serviceRoot.webView!
            .evalJavascript('api.derive.elections.info()')
        as FutureOr<Map<dynamic, dynamic>?>);
    return info;
  }

  Future<List?> queryCouncilMotions() async {
    final List? data =
        await (serviceRoot.webView!.evalJavascript('gov.getCouncilMotions(api)')
            as FutureOr<List<dynamic>?>);
    return data;
  }

  Future<Map?> queryTreasuryOverview() async {
    final Map? data = await (serviceRoot.webView!
            .evalJavascript('gov.getTreasuryOverview(api)')
        as FutureOr<Map<dynamic, dynamic>?>);
    return data;
  }

  Future<List?> queryTreasuryTips() async {
    final List? data =
        await (serviceRoot.webView!.evalJavascript('gov.getTreasuryTips(api)')
            as FutureOr<List<dynamic>?>);
    return data;
  }
}

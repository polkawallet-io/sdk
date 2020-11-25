import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/gov/genExternalLinksParams.dart';
import 'package:polkawallet_sdk/api/types/gov/proposalInfoData.dart';
import 'package:polkawallet_sdk/api/types/gov/treasuryOverviewData.dart';
import 'package:polkawallet_sdk/service/gov.dart';

class ApiGov {
  ApiGov(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceGov service;

  Future<List> getDemocracyUnlocks(String address) async {
    final List res = await service.getDemocracyUnlocks(address);
    return res;
  }

  Future<List> getExternalLinks(GenExternalLinksParams params) async {
    final List res = await service.getExternalLinks(params.toJson());
    return res;
  }

  Future<List> getReferendumVoteConvictions() async {
    final List res = await service.getReferendumVoteConvictions();
    return res;
  }

  Future<List> queryReferendums(String address) async {
    final List data = await service.queryReferendums(address);
    return data;
  }

  Future<List<ProposalInfoData>> queryProposals() async {
    final List data = await service.queryProposals();
    return data
        .map((e) => ProposalInfoData.fromJson(Map<String, dynamic>.of(e)))
        .toList();
  }

  Future<Map> queryTreasuryProposal(String id) async {
    final Map data = await service.queryTreasuryProposal(id);
    return data;
  }

  Future<Map> queryCouncilVotes() async {
    final Map votes = await service.queryCouncilVotes();
    return votes;
  }

  Future<Map> queryUserCouncilVote(String address) async {
    final Map votes = await service.queryUserCouncilVote(address);
    return votes;
  }

  Future<Map> queryCouncilInfo() async {
    final Map info = await service.queryCouncilInfo();
    return info;
  }

  Future<List<CouncilMotionData>> queryCouncilMotions() async {
    final List data = await service.queryCouncilMotions();
    if (data != null) {
      return data
          .map((e) => CouncilMotionData.fromJson(Map<String, dynamic>.of(e)))
          .toList();
    }
    return [];
  }
}

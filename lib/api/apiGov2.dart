import 'dart:async';

import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/gov/genExternalLinksParams.dart';
import 'package:polkawallet_sdk/api/types/gov/referendumV2Data.dart';
import 'package:polkawallet_sdk/service/gov2.dart';

class ApiGov2 {
  ApiGov2(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceGov2 service;

  Future<bool> checkGovExist(int version) async {
    return service.checkGovExist(version);
  }

  Future<ReferendumData> queryReferendums(String address) async {
    final Map res = await service.queryReferendums(address);
    final ongoing = List<ReferendumGroup>.from(
        res['ongoing'].map((e) => ReferendumGroup.fromJson(e)));
    final userVotes = List<ReferendumVote>.from(
        res['userVotes'].map((e) => ReferendumVote.fromJson(e)));
    return ReferendumData(ongoing: ongoing, userVotes: userVotes);
  }

  Future<List?> getExternalLinks(GenExternalLinksParams params) async {
    final List? res = await service.getExternalLinks(params.toJson());
    return res;
  }

  Future<List?> getReferendumVoteConvictions() async {
    final List? res = await service.getReferendumVoteConvictions();
    return res;
  }
}

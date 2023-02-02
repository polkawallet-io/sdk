import 'dart:async';

import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/gov/genExternalLinksParams.dart';
import 'package:polkawallet_sdk/service/gov2.dart';

class ApiGov2 {
  ApiGov2(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceGov2 service;

  Future<bool> checkGovExist(int version) async {
    return service.checkGovExist(version);
  }

  Future<List?> getDemocracyUnlocks(String address) async {
    final List? res = await service.getDemocracyUnlocks(address);
    return res;
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

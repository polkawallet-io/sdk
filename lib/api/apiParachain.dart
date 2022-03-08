import 'dart:async';

import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/parachain/auctionData.dart';
import 'package:polkawallet_sdk/api/types/parachain/parasOverviewData.dart';
import 'package:polkawallet_sdk/service/parachain.dart';

class ApiParachain {
  ApiParachain(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceParachain service;

  Future<ParasOverviewData> queryParasOverview() async {
    final res = await service.queryParasOverview();
    return ParasOverviewData.fromJson(res ?? {});
  }

  Future<AuctionData> queryAuctionWithWinners() async {
    final res = await service.queryAuctionWithWinners();
    return AuctionData.fromJson(res!);
  }

  Future<List<String>> queryUserContributions(
      List<String> paraIds, String pubKey) async {
    return service.queryUserContributions(paraIds, pubKey);
  }
}

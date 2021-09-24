import 'dart:async';

import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/parachain/auctionData.dart';
import 'package:polkawallet_sdk/service/parachain.dart';

class ApiParachain {
  ApiParachain(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceParachain service;

  Future<AuctionData> queryAuctionWithWinners() async {
    final res = await (service.queryAuctionWithWinners()
        as FutureOr<Map<dynamic, dynamic>>);
    return AuctionData.fromJson(res);
  }

  Future<List<String>> queryUserContributions(
      List<String> paraIds, String pubKey) async {
    return service.queryUserContributions(paraIds, pubKey);
  }
}

import 'dart:async';

import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/balanceData.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/service/assets.dart';

class ApiAssets {
  ApiAssets(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceAssets service;

  Future<List<TokenBalanceData>> getAssetsAll() async {
    final List res = await (service.getAssetsAll() as FutureOr<List<dynamic>>);
    return res
        .map((e) => TokenBalanceData(
              id: e['id'].toString(),
              name: e['symbol'],
              fullName: e['name'],
              symbol: e['symbol'],
              decimals: int.parse(e['decimals']),
            ))
        .toList();
  }

  Future<List<AssetsBalanceData>> queryAssetsBalances(
      List<String> ids, String address) async {
    final res = await (service.queryAssetsBalances(ids, address)
        as FutureOr<List<dynamic>>);
    return res
        .asMap()
        .map((k, v) {
          v['id'] = ids[k];
          return MapEntry(k, AssetsBalanceData.fromJson(v));
        })
        .values
        .toList();
  }
}

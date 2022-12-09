import 'dart:async';

import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/staking/accountBondedInfo.dart';
import 'package:polkawallet_sdk/api/types/staking/ownStashInfo.dart';
import 'package:polkawallet_sdk/service/staking.dart';

class ApiStaking {
  ApiStaking(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceStaking service;

  Future<Map?> queryElectedInfo() async {
    Map? data = await service.queryElectedInfo();
    return data;
  }

  Future<Map?> queryNominations() async {
    final res = await service.queryNominations();
    return res;
  }

  Future<Map?> queryNominationsCount() async {
    final res = await service.queryNominationsCount();
    return res;
  }

  /// query staking stash-controller relationship of a list of pubKeys,
  /// return list of [pubKey, controllerAddress, stashAddress].
  Future<Map<String?, AccountBondedInfo>> queryBonded(
      List<String> pubKeys) async {
    if (pubKeys.length == 0) {
      return {};
    }
    final res = Map<String?, AccountBondedInfo>();
    final List data =
        await (service.queryBonded(pubKeys) as FutureOr<List<dynamic>>);
    data.forEach((e) {
      res[e[0]] = AccountBondedInfo(e[0], e[1], e[2]);
    });
    return res;
  }

  Future<OwnStashInfoData> queryOwnStashInfo(String accountId) async {
    final Map data = await (service.queryOwnStashInfo(accountId));
    return OwnStashInfoData.fromJson(
        Map<String, dynamic>.of(data as Map<String, dynamic>));
  }

  Future<Map?> loadValidatorRewardsData(String validatorId) async {
    Map? data = await service.loadValidatorRewardsData(validatorId);
    return data;
  }

  Future<List?> getAccountRewardsEraOptions() async {
    final List? res = await service.getAccountRewardsEraOptions();
    return res;
  }

  // this query takes extremely long time
  Future<Map?> queryAccountRewards(String address, int eras) async {
    final Map? res = await service.fetchAccountRewards(address, eras);
    return res;
  }

  Future<int?> getSlashingSpans(String stashId) async {
    final int? spans = await service.getSlashingSpans(stashId);
    return spans;
  }
}

import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/service/staking.dart';

class ApiStaking {
  ApiStaking(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceStaking service;

  Future<Map> queryOverview() async {
    final res = await service.queryOverview();
    return res;
  }

  Future<Map> queryElectedInfo() async {
    Map data = await service.queryElectedInfo();
    return data;
  }

  /// query staking stash-controller relationship of a list of pubKeys,
  /// return list of [pubKey, controllerAddress, stashAddress].
  Future<List> queryBonded(List<String> pubKeys) async {
    if (pubKeys == null || pubKeys.length == 0) {
      return [];
    }
    List res = await service.queryBonded(pubKeys);
    return res;
  }

  Future<Map> queryOwnStashInfo(String accountId) async {
    Map data = await service.queryOwnStashInfo(accountId);
    return data;
  }

  Future<Map> loadValidatorRewardsData(String validatorId) async {
    Map data = await service.loadValidatorRewardsData(validatorId);
    return data;
  }

  Future<List> getAccountRewardsEraOptions() async {
    final List res = await service.getAccountRewardsEraOptions();
    return res;
  }

  // this query takes extremely long time
  Future<Map> queryAccountRewards(String address, int eras) async {
    final Map res = await service.fetchAccountRewards(address, eras);
    return res;
  }
}

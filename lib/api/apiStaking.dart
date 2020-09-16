import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/service/staking.dart';

class ApiStaking {
  ApiStaking(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceStaking service;

  /// query staking stash-controller relationship of a list of pubKeys,
  /// return list of [pubKey, controllerAddress, stashAddress].
  Future<List> queryBonded(List<String> pubKeys) async {
    if (pubKeys == null || pubKeys.length == 0) {
      return [];
    }
    List res = await service.queryBonded(pubKeys);
    return res;
  }
}

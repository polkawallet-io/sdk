import 'dart:convert';

import 'package:polkawallet_sdk/service/index.dart';

class ServiceStaking {
  ServiceStaking(this.serviceRoot);

  final SubstrateService serviceRoot;

  /// query staking info of a list of pubKeys
  Future<List> queryBonded(List<String> pubKeys) async {
    List res = await serviceRoot.evalJavascript(
        'account.queryAccountsBonded(api, ${jsonEncode(pubKeys)})');
    return res;
  }
}

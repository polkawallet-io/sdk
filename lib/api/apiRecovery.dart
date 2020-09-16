import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/service/staking.dart';

class ApiRecovery {
  ApiRecovery(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceStaking service;
}

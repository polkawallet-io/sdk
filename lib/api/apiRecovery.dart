import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/recoveryInfo.dart';
import 'package:polkawallet_sdk/service/recovery.dart';

class ApiRecovery {
  ApiRecovery(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceRecovery service;

  Future<RecoveryInfo> queryRecoverable(String address) async {
//    address = "J4sW13h2HNerfxTzPGpLT66B3HVvuU32S6upxwSeFJQnAzg";
    Map res = await service.queryRecoverable(address);
    if (res != null) {
      res['address'] = address;
    }
    return RecoveryInfo.fromJson(res);
  }

  Future<List> queryRecoveryProxies(List<String> addresses) async {
    final res = await service.queryRecoveryProxies(addresses);
    return res;
  }
}

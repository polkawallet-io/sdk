import 'dart:async';

import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/networkStateData.dart';
import 'package:polkawallet_sdk/service/setting.dart';

class ApiSetting {
  ApiSetting(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceSetting service;

  /// query network const.
  Future<Map> queryNetworkConst() async {
    final Map res = await service.queryNetworkConst();
    return res;
  }

  /// query network properties.
  Future<NetworkStateData> queryNetworkProps() async {
    final Map res = await service.queryNetworkProps();
    if (res == null) {
      return null;
    }
    return NetworkStateData.fromJson(res);
  }

  /// subscribe best number.
  Future<void> subscribeBestNumber(Function callback) async {
    service.subscribeBestNumber(callback);
  }

  /// unsubscribe best number.
  Future<void> unsubscribeBestNumber() async {
    service.unsubscribeBestNumber();
  }
}

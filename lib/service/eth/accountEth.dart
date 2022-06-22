import 'dart:convert';

import 'package:polkawallet_sdk/service/index.dart';

class ServiceAccountEth {
  ServiceAccountEth(this.serviceRoot);

  final SubstrateService serviceRoot;

  /// Get icons of addresses
  /// return svg strings
  Future<List?> getAddressIcons(List addresses) async {
    final dynamic res = await serviceRoot.webView!
        .evalJavascript('eth.account.genIcons(${jsonEncode(addresses)})');
    return res;
  }
}

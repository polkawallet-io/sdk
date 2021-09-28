import 'dart:convert';

import 'package:polkawallet_sdk/service/index.dart';

class ETHServiceAccount {
  ETHServiceAccount(this.serviceRoot);

  final SubstrateService serviceRoot;

  Future<List?> getAddressIcons(List addresses) async {
    final dynamic res = await serviceRoot.webView!
        .evalJavascript('eth.account.genIcons(${jsonEncode(addresses)})');
    return res;
  }
}

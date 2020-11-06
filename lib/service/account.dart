import 'dart:convert';

import 'package:polkawallet_sdk/service/index.dart';

class ServiceAccount {
  ServiceAccount(this.serviceRoot);

  final SubstrateService serviceRoot;

  /// encode addresses to publicKeys
  Future<Map> encodeAddress(List<String> pubKeys, ss58List) async {
    Map res = await serviceRoot.webView.evalJavascript(
        'account.encodeAddress(${jsonEncode(pubKeys)}, ${jsonEncode(ss58List)})');
    return res;
  }

  /// decode addresses to publicKeys
  Future<Map> decodeAddress(List<String> addresses) async {
    Map res = await serviceRoot.webView
        .evalJavascript('account.decodeAddress(${jsonEncode(addresses)})');
    return res;
  }

  /// query balance
  Future<Map> queryBalance(String address) async {
    final res = await serviceRoot.webView
        .evalJavascript('account.getBalance(api, "$address")');
    return res;
  }

  /// Get on-chain account info of addresses
  Future<List> queryIndexInfo(List addresses) async {
    var res = await serviceRoot.webView.evalJavascript(
        'account.getAccountIndex(api, ${jsonEncode(addresses)})');
    return res;
  }

  /// query address with account index
  Future<List> queryAddressWithAccountIndex(String index, int ss58) async {
    final res = await serviceRoot.webView.evalJavascript(
        'account.queryAddressWithAccountIndex(api, "$index", $ss58)');
    return res;
  }

  Future<List> getPubKeyIcons(List<String> keys) async {
    List res = await serviceRoot.webView
        .evalJavascript('account.genPubKeyIcons(${jsonEncode(keys)})');
    return res;
  }

  Future<List> getAddressIcons(List addresses) async {
    List res = await serviceRoot.webView
        .evalJavascript('account.genIcons(${jsonEncode(addresses)})');
    return res;
  }
}

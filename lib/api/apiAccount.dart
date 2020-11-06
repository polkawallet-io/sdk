import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/balanceData.dart';
import 'package:polkawallet_sdk/service/account.dart';

class ApiAccount {
  ApiAccount(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceAccount service;

  /// encode addresses to publicKeys
  Future<Map> encodeAddress(List<String> pubKeys) async {
    final int ss58 = apiRoot.connectedNode.ss58;
    final Map res = await service.encodeAddress(pubKeys, [ss58]);
    if (res != null) {
      return res[ss58.toString()];
    }
    return null;
  }

  /// decode addresses to publicKeys
  Future<Map> decodeAddress(List<String> addresses) async {
    final Map res = await service.decodeAddress(addresses);
    return res;
  }

  /// query balance
  Future<BalanceData> queryBalance(String address) async {
    final res = await service.queryBalance(address);
    return res != null ? BalanceData.fromJson(res) : null;
  }

  /// subscribe balance
  /// @return [String] msgChannel, call unsubscribeMessage(msgChannel) to unsub.
  Future<String> subscribeBalance(
    String address,
    Function(BalanceData) onUpdate,
  ) async {
    final msgChannel = 'Balance';
    final code = 'account.getBalance(api, "$address", "$msgChannel")';
    await apiRoot.subscribeMessage(
        code, msgChannel, (data) => onUpdate(BalanceData.fromJson(data)));
    return msgChannel;
  }

  /// unsubscribe balance
  void unsubscribeBalance() {
    final msgChannel = 'Balance';
    apiRoot.unsubscribeMessage(msgChannel);
  }

  /// Get on-chain account info of addresses
  Future<List> queryIndexInfo(List addresses) async {
    if (addresses == null || addresses.length == 0) {
      return [];
    }

    var res = await service.queryIndexInfo(addresses);
    return res;
  }

  /// query address with account index
  Future<String> queryAddressWithAccountIndex(String index) async {
    final res = await service.queryAddressWithAccountIndex(
        index, apiRoot.connectedNode.ss58);
    if (res != null) {
      return res[0];
    }
    return null;
  }

  /// Get icons of pubKeys
  /// return svg strings
  Future<List> getPubKeyIcons(List<String> keys) async {
    if (keys == null || keys.length == 0) {
      return [];
    }
    List res = await service.getPubKeyIcons(keys);
    return res;
  }

  /// Get icons of addresses
  /// return svg strings
  Future<List> getAddressIcons(List addresses) async {
    if (addresses == null || addresses.length == 0) {
      return [];
    }
    List res = await service.getAddressIcons(addresses);
    return res;
  }
}

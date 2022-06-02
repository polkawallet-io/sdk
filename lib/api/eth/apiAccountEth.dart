import 'package:polkawallet_sdk/service/eth/accountEth.dart';
import 'package:polkawallet_sdk/storage/keyringEVM.dart';

import '../api.dart';

class ApiAccountEth {
  ApiAccountEth(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceAccountEth service;

  /// This method query account icons and set icons to [Keyring.store]
  /// so we can get icon of an account from [Keyring] instance.
  Future<void> updateAddressIconsMap(KeyringEVM keyring,
      [List? address]) async {
    final List<String?> ls = [];
    if (address != null) {
      ls.addAll(List<String>.from(address));
    } else {
      ls.addAll(keyring.keyPairs.map((e) => e.address).toList());
      ls.addAll(keyring.contacts.map((e) => e.address).toList());
    }

    if (ls.length == 0) return;
    // get icons from webView.
    final res = await service.getAddressIcons(ls);
    // set new icons to Keyring instance.
    if (res != null) {
      final data = {};
      res.forEach((e) {
        data[e[0]] = e[1];
      });
      keyring.store.updateIconsMap(Map<String, String>.from(data));
    }
  }
}

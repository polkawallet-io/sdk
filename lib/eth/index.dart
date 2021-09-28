import 'package:polkawallet_sdk/service/index.dart';

import 'account.dart';
import 'keyring.dart';

class EthereumService {
  late ETHServiceAccount account;
  late ETHServiceKeyring keyring;

  EthereumService.init(SubstrateService serviceRoot) {
    account = ETHServiceAccount(serviceRoot);
    keyring = ETHServiceKeyring(serviceRoot);
  }
}

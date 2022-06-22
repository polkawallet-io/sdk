import 'package:polkawallet_sdk/service/eth/accountEth.dart';
import 'package:polkawallet_sdk/service/eth/keyringEth.dart';
import 'package:polkawallet_sdk/service/index.dart';

class ServiceEth {
  ServiceEth(SubstrateService serviceRoot) {
    account = ServiceAccountEth(serviceRoot);
    keyring = ServiceKeyringEth(serviceRoot);
  }

  late ServiceAccountEth account;
  late ServiceKeyringEth keyring;
}

import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/eth/apiAccountEth.dart';
import 'package:polkawallet_sdk/api/eth/apiKeyringEth.dart';
import 'package:polkawallet_sdk/service/eth/index.dart';

class ApiEth {
  ApiEth(PolkawalletApi apiRoot, ServiceEth service) {
    account = ApiAccountEth(apiRoot, service.account);
    keyring = ApiKeyringEth(apiRoot, service.keyring);
  }

  late ApiAccountEth account;
  late ApiKeyringEth keyring;
}

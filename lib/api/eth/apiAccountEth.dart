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

  Future<String> getNativeTokenBalance(String address) async {
    return service.getNativeTokenBalance(address);
  }

  Future<List?> getTokenBalance(
      String address, List<String> contractAddresses) async {
    final List? res = await service.getTokenBalance(address, contractAddresses);
    return res;
  }

  Future<String?> getAddress(String address) async {
    final String? res = await service.getAddress(address);
    return res;
  }

  Map<String, String> getAcalaGasParams() {
    return {"gasPrice": "0x33a70303ea", "gasLimit": "0x329b140"};
  }

  Future<EvmGasParams> queryEthGasParams({int gasLimit = 200000}) async {
    final data = await service.queryEthGasParams();
    return EvmGasParams(
      gasLimit: gasLimit,
      gasPrice: double.parse(data['estimatedBaseFee']),
      estimatedBaseFee: double.parse(data['estimatedBaseFee']),
      estimatedFee: {
        EstimatedFeeLevel.low: EvmGasParamsEIP1559(
            maxFeePerGas: double.parse(data['low']['suggestedMaxFeePerGas']),
            maxPriorityFeePerGas:
                double.parse(data['low']['suggestedMaxPriorityFeePerGas'])),
        EstimatedFeeLevel.medium: EvmGasParamsEIP1559(
            maxFeePerGas: double.parse(data['medium']['suggestedMaxFeePerGas']),
            maxPriorityFeePerGas:
                double.parse(data['medium']['suggestedMaxPriorityFeePerGas'])),
        EstimatedFeeLevel.high: EvmGasParamsEIP1559(
            maxFeePerGas: double.parse(data['high']['suggestedMaxFeePerGas']),
            maxPriorityFeePerGas:
                double.parse(data['high']['suggestedMaxPriorityFeePerGas']))
      },
    );
  }
}

class EvmGasParams {
  EvmGasParams(
      {required this.gasLimit,
      required this.gasPrice,
      this.estimatedBaseFee,
      this.estimatedFee});
  final int gasLimit;
  final double gasPrice;
  final double? estimatedBaseFee;
  final Map<EstimatedFeeLevel, EvmGasParamsEIP1559>? estimatedFee;
}

class EvmGasParamsEIP1559 {
  EvmGasParamsEIP1559(
      {required this.maxFeePerGas, required this.maxPriorityFeePerGas});
  final double maxFeePerGas;
  final double maxPriorityFeePerGas;
}

enum EstimatedFeeLevel { low, medium, high }

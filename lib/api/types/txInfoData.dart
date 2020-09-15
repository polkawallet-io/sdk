import 'package:json_annotation/json_annotation.dart';
import 'package:polkawallet_sdk/api/types/keyPairData.dart';

part 'txInfoData.g.dart';

@JsonSerializable(explicitToJson: true)
class TxInfoData extends _TxInfoData {
  static TxInfoData fromJson(Map<String, dynamic> json) =>
      _$TxInfoDataFromJson(json);
  static Map<String, dynamic> toJson(TxInfoData tx) => _$TxInfoDataToJson(tx);
}

/// call api.tx[module][call](...params) with polkadot-js/api
/// see https://polkadot.js.org/api/substrate/extrinsics.html
/// for all available calls and params.
abstract class _TxInfoData {
  String module;
  String call;
  KeyPairData keyPair;
  String tip;

  bool isUnsigned = false;

  /// proxy for calling recovery.asRecovered
  KeyPairData proxy;

  /// txName for calling treasury.approveProposal & treasury.rejectProposal
  String txName;
}

@JsonSerializable()
class TxFeeEstimateResult extends _TxFeeEstimateResult {
  static TxFeeEstimateResult fromJson(Map<String, dynamic> json) =>
      _$TxFeeEstimateResultFromJson(json);
  static Map<String, dynamic> toJson(TxFeeEstimateResult res) =>
      _$TxFeeEstimateResultToJson(res);
}

abstract class _TxFeeEstimateResult {
  dynamic weight;
  dynamic partialFee;
}

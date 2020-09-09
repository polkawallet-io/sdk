import 'package:json_annotation/json_annotation.dart';

part 'txInfoData.g.dart';

@JsonSerializable()
class TxInfoData extends _TxInfoData {
  static TxInfoData fromJson(Map<String, dynamic> json) =>
      _$TxInfoDataFromJson(json);
  static Map<String, dynamic> toJson(TxInfoData tx) => _$TxInfoDataToJson(tx);
}

abstract class _TxInfoData {
  String module;
  String call;
  String pubKey;
  String password;
  String tip;

  bool isUnsigned = false;

  /// proxy for calling recovery.asRecovered
  String proxy;
  String address;

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

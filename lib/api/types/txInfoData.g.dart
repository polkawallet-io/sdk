// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'txInfoData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TxInfoData _$TxInfoDataFromJson(Map<String, dynamic> json) {
  return TxInfoData()
    ..module = json['module'] as String
    ..call = json['call'] as String
    ..keyPair = json['keyPair'] == null
        ? null
        : KeyPairData.fromJson(json['keyPair'] as Map<String, dynamic>)
    ..tip = json['tip'] as String
    ..isUnsigned = json['isUnsigned'] as bool
    ..proxy = json['proxy'] == null
        ? null
        : KeyPairData.fromJson(json['proxy'] as Map<String, dynamic>)
    ..txName = json['txName'] as String;
}

Map<String, dynamic> _$TxInfoDataToJson(TxInfoData instance) =>
    <String, dynamic>{
      'module': instance.module,
      'call': instance.call,
      'keyPair': instance.keyPair?.toJson(),
      'tip': instance.tip,
      'isUnsigned': instance.isUnsigned,
      'proxy': instance.proxy?.toJson(),
      'txName': instance.txName,
    };

TxFeeEstimateResult _$TxFeeEstimateResultFromJson(Map<String, dynamic> json) {
  return TxFeeEstimateResult()
    ..weight = json['weight']
    ..partialFee = json['partialFee'];
}

Map<String, dynamic> _$TxFeeEstimateResultToJson(
        TxFeeEstimateResult instance) =>
    <String, dynamic>{
      'weight': instance.weight,
      'partialFee': instance.partialFee,
    };

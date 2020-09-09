// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'txInfoData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TxInfoData _$TxInfoDataFromJson(Map<String, dynamic> json) {
  return TxInfoData()
    ..module = json['module'] as String
    ..call = json['call'] as String
    ..pubKey = json['pubKey'] as String
    ..address = json['address'] as String
    ..password = json['password'] as String
    ..tip = json['tip'] as String
    ..isUnsigned = json['isUnsigned'] as bool
    ..proxy = json['proxy'] as String
    ..txName = json['txName'] as String;
}

Map<String, dynamic> _$TxInfoDataToJson(TxInfoData instance) =>
    <String, dynamic>{
      'module': instance.module,
      'call': instance.call,
      'pubKey': instance.pubKey,
      'address': instance.address,
      'password': instance.password,
      'tip': instance.tip,
      'isUnsigned': instance.isUnsigned,
      'proxy': instance.proxy,
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

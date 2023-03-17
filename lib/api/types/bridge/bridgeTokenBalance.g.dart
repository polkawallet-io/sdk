// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bridgeTokenBalance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BridgeTokenBalance _$BridgeTokenBalanceFromJson(Map<String, dynamic> json) =>
    BridgeTokenBalance(
      token: json['token'] as String,
      free: json['free'] as String,
      available: json['available'] as String,
      locked: json['locked'] as String,
      reserved: json['reserved'] as String,
      decimals: json['decimals'] as int,
    );

Map<String, dynamic> _$BridgeTokenBalanceToJson(BridgeTokenBalance instance) =>
    <String, dynamic>{
      'token': instance.token,
      'free': instance.free,
      'available': instance.available,
      'locked': instance.locked,
      'reserved': instance.reserved,
      'decimals': instance.decimals,
    };

BridgeAmountInputConfig _$BridgeAmountInputConfigFromJson(
        Map<String, dynamic> json) =>
    BridgeAmountInputConfig(
      token: json['token'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      address: json['address'] as String,
      minInput: json['minInput'] as String,
      maxInput: json['maxInput'] as String,
      destFee:
          BridgeDestFeeData.fromJson(json['destFee'] as Map<String, dynamic>),
      estimateFee: json['estimateFee'] as String,
    );

Map<String, dynamic> _$BridgeAmountInputConfigToJson(
        BridgeAmountInputConfig instance) =>
    <String, dynamic>{
      'token': instance.token,
      'from': instance.from,
      'to': instance.to,
      'address': instance.address,
      'minInput': instance.minInput,
      'maxInput': instance.maxInput,
      'destFee': instance.destFee,
      'estimateFee': instance.estimateFee,
    };

BridgeDestFeeData _$BridgeDestFeeDataFromJson(Map<String, dynamic> json) =>
    BridgeDestFeeData(
      token: json['token'] as String,
      amount: json['amount'] as String,
      decimals: json['decimals'] as int,
    );

Map<String, dynamic> _$BridgeDestFeeDataToJson(BridgeDestFeeData instance) =>
    <String, dynamic>{
      'token': instance.token,
      'amount': instance.amount,
      'decimals': instance.decimals,
    };

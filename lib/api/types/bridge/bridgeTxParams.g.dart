// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bridgeTxParams.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BridgeTxParams _$BridgeTxParamsFromJson(Map<String, dynamic> json) =>
    BridgeTxParams(
      module: json['module'] as String,
      call: json['call'] as String,
      params: json['params'] as List<dynamic>,
      txHex: json['txHex'] as String,
    );

Map<String, dynamic> _$BridgeTxParamsToJson(BridgeTxParams instance) =>
    <String, dynamic>{
      'module': instance.module,
      'call': instance.call,
      'params': instance.params,
      'txHex': instance.txHex,
    };

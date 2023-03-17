// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'networkParams.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkParams _$NetworkParamsFromJson(Map<String, dynamic> json) =>
    NetworkParams()
      ..name = json['name'] as String?
      ..endpoint = json['endpoint'] as String?
      ..ss58 = json['ss58'] as int?
      ..chainId = json['chainId'] as String?
      ..networkType = json['networkType'] as String?;

Map<String, dynamic> _$NetworkParamsToJson(NetworkParams instance) =>
    <String, dynamic>{
      'name': instance.name,
      'endpoint': instance.endpoint,
      'ss58': instance.ss58,
      'chainId': instance.chainId,
      'networkType': instance.networkType,
    };

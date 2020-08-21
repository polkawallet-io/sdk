// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'networkParams.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkParams _$NetworkParamsFromJson(Map<String, dynamic> json) {
  return NetworkParams()
    ..name = json['name'] as String
    ..endpoint = json['endpoint'] as String
    ..ss58 = json['ss58'] as int;
}

Map<String, dynamic> _$NetworkParamsToJson(NetworkParams instance) =>
    <String, dynamic>{
      'name': instance.name,
      'endpoint': instance.endpoint,
      'ss58': instance.ss58,
    };

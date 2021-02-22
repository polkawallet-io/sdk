// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payloadData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WCPayloadData _$WCPayloadDataFromJson(Map<String, dynamic> json) {
  return WCPayloadData()
    ..topic = json['topic'] as String
    ..chainId = json['chainId'] as String
    ..payload = json['payload'] == null
        ? null
        : WCPayload.fromJson(json['payload'] as Map<String, dynamic>);
}

Map<String, dynamic> _$WCPayloadDataToJson(WCPayloadData instance) =>
    <String, dynamic>{
      'topic': instance.topic,
      'chainId': instance.chainId,
      'payload': instance.payload?.toJson(),
    };

WCPayload _$WCPayloadFromJson(Map<String, dynamic> json) {
  return WCPayload()
    ..id = json['id'] as int
    ..method = json['method'] as String
    ..params = json['params'] as List;
}

Map<String, dynamic> _$WCPayloadToJson(WCPayload instance) => <String, dynamic>{
      'id': instance.id,
      'method': instance.method,
      'params': instance.params,
    };

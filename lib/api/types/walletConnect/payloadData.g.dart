// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payloadData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WCPayloadData _$WCPayloadDataFromJson(Map<String, dynamic> json) =>
    WCPayloadData()
      ..topic = json['topic'] as String?
      ..chainId = json['chainId'] as String?
      ..payload = json['payload'] == null
          ? null
          : WCPayload.fromJson(json['payload'] as Map<String, dynamic>);

Map<String, dynamic> _$WCPayloadDataToJson(WCPayloadData instance) =>
    <String, dynamic>{
      'topic': instance.topic,
      'chainId': instance.chainId,
      'payload': instance.payload?.toJson(),
    };

WCPayload _$WCPayloadFromJson(Map<String, dynamic> json) => WCPayload()
  ..id = json['id'] as int?
  ..method = json['method'] as String?
  ..params = json['params'] as List<dynamic>?;

Map<String, dynamic> _$WCPayloadToJson(WCPayload instance) => <String, dynamic>{
      'id': instance.id,
      'method': instance.method,
      'params': instance.params,
    };

WCCallRequestData _$WCCallRequestDataFromJson(Map<String, dynamic> json) =>
    WCCallRequestData()
      ..event = json['event'] as String?
      ..topic = json['topic'] as String?
      ..id = json['id'] as int?
      ..params = (json['params'] as List<dynamic>?)
          ?.map(
              (e) => WCCallRequestParamItem.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$WCCallRequestDataToJson(WCCallRequestData instance) =>
    <String, dynamic>{
      'event': instance.event,
      'topic': instance.topic,
      'id': instance.id,
      'params': instance.params,
    };

WCCallRequestParamItem _$WCCallRequestParamItemFromJson(
        Map<String, dynamic> json) =>
    WCCallRequestParamItem()
      ..label = json['label'] as String?
      ..value = json['value'];

Map<String, dynamic> _$WCCallRequestParamItemToJson(
        WCCallRequestParamItem instance) =>
    <String, dynamic>{
      'label': instance.label,
      'value': instance.value,
    };

WCCallRequestResult _$WCCallRequestResultFromJson(Map<String, dynamic> json) =>
    WCCallRequestResult()
      ..result = json['result'] as String?
      ..error = json['error'] as String?;

Map<String, dynamic> _$WCCallRequestResultToJson(
        WCCallRequestResult instance) =>
    <String, dynamic>{
      'result': instance.result,
      'error': instance.error,
    };

import 'package:json_annotation/json_annotation.dart';

part 'payloadData.g.dart';

@JsonSerializable(explicitToJson: true)
class WCPayloadData extends _WCPayloadData {
  static WCPayloadData fromJson(Map json) =>
      _$WCPayloadDataFromJson(json as Map<String, dynamic>);
  Map toJson() => _$WCPayloadDataToJson(this);
}

abstract class _WCPayloadData {
  String? topic;
  String? chainId;
  WCPayload? payload;
}

@JsonSerializable()
class WCPayload extends _WCPayload {
  static WCPayload fromJson(Map json) =>
      _$WCPayloadFromJson(json as Map<String, dynamic>);
  Map toJson() => _$WCPayloadToJson(this);
}

abstract class _WCPayload {
  int? id;
  String? method;
  List? params;
}

@JsonSerializable()
class WCCallRequestData extends _WCCallRequestData {
  static WCCallRequestData fromJson(Map json) =>
      _$WCCallRequestDataFromJson(json as Map<String, dynamic>);
  Map toJson() => _$WCCallRequestDataToJson(this);
}

abstract class _WCCallRequestData {
  String? event;
  int? id;
  List<WCCallRequestParamItem>? params;
}

@JsonSerializable()
class WCCallRequestParamItem extends _WCCallRequestParamItem {
  static WCCallRequestParamItem fromJson(Map json) =>
      _$WCCallRequestParamItemFromJson(json as Map<String, dynamic>);
  Map toJson() => _$WCCallRequestParamItemToJson(this);
}

abstract class _WCCallRequestParamItem {
  String? label;
  dynamic value;
}

@JsonSerializable()
class WCCallRequestResult extends _WCCallRequestResult {
  static WCCallRequestResult fromJson(Map json) =>
      _$WCCallRequestResultFromJson(json as Map<String, dynamic>);
  Map toJson() => _$WCCallRequestResultToJson(this);
}

abstract class _WCCallRequestResult {
  String? result;
  String? error;
}

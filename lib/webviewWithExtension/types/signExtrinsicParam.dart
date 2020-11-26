import 'package:json_annotation/json_annotation.dart';

part 'signExtrinsicParam.g.dart';

@JsonSerializable()
class SignAsExtensionParam extends _SignAsExtensionParam {
  static SignAsExtensionParam fromJson(Map<String, dynamic> json) =>
      _$SignAsExtensionParamFromJson(json);
  static Map<String, dynamic> toJson(SignAsExtensionParam params) =>
      _$SignAsExtensionParamToJson(params);
}

abstract class _SignAsExtensionParam {
  String id;
  String url;
  String msgType;
  dynamic request;
}

@JsonSerializable()
class SignExtrinsicRequest extends _SignExtrinsicRequest {
  static SignExtrinsicRequest fromJson(Map<String, dynamic> json) =>
      _$SignExtrinsicRequestFromJson(json);
  static Map<String, dynamic> toJson(SignExtrinsicRequest req) =>
      _$SignExtrinsicRequestToJson(req);
}

abstract class _SignExtrinsicRequest {
  String address;
  String blockHash;
  String blockNumber;
  String era;
  String genesisHash;
  String method;
  String nonce;
  List<String> signedExtensions;
  String specVersion;
  String tip;
  String transactionVersion;
  int version;
}

@JsonSerializable()
class SignBytesRequest extends _SignBytesRequest {
  static SignBytesRequest fromJson(Map<String, dynamic> json) =>
      _$SignBytesRequestFromJson(json);
  static Map<String, dynamic> toJson(SignBytesRequest req) =>
      _$SignBytesRequestToJson(req);
}

abstract class _SignBytesRequest {
  String address;
  String data;
  String type;
}

@JsonSerializable()
class ExtensionSignResult extends _ExtensionSignResult {
  static ExtensionSignResult fromJson(Map<String, dynamic> json) =>
      _$ExtensionSignResultFromJson(json);
  static Map<String, dynamic> toJson(ExtensionSignResult res) =>
      _$ExtensionSignResultToJson(res);
}

abstract class _ExtensionSignResult {
  String id;
  String signature;
}

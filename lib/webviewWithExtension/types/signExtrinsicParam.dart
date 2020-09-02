import 'package:json_annotation/json_annotation.dart';

part 'signExtrinsicParam.g.dart';

@JsonSerializable()
class SignExtrinsicParam extends _SignExtrinsicParam {
  static SignExtrinsicParam fromJson(Map<String, dynamic> json) =>
      _$SignExtrinsicParamFromJson(json);
  static Map<String, dynamic> toJson(SignExtrinsicParam params) =>
      _$SignExtrinsicParamToJson(params);
}

abstract class _SignExtrinsicParam {
  String id;
  String url;
  String msgType;
  SignExtrinsicRequest request;
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
class SignBytesParam extends _SignBytesParam {
  static SignBytesParam fromJson(Map<String, dynamic> json) =>
      _$SignBytesParamFromJson(json);
  static Map<String, dynamic> toJson(SignBytesParam params) =>
      _$SignBytesParamToJson(params);
}

abstract class _SignBytesParam {
  String id;
  String url;
  String msgType;
  SignBytesRequest request;
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

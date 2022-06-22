// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signExtrinsicParam.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignAsExtensionParam _$SignAsExtensionParamFromJson(
        Map<String, dynamic> json) =>
    SignAsExtensionParam()
      ..id = json['id'] as String?
      ..url = json['url'] as String?
      ..msgType = json['msgType'] as String?
      ..request = json['request'] as Map<String, dynamic>?;

Map<String, dynamic> _$SignAsExtensionParamToJson(
        SignAsExtensionParam instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'msgType': instance.msgType,
      'request': instance.request,
    };

SignExtrinsicRequest _$SignExtrinsicRequestFromJson(
        Map<String, dynamic> json) =>
    SignExtrinsicRequest()
      ..address = json['address'] as String?
      ..blockHash = json['blockHash'] as String?
      ..blockNumber = json['blockNumber'] as String?
      ..era = json['era'] as String?
      ..genesisHash = json['genesisHash'] as String?
      ..method = json['method'] as String?
      ..nonce = json['nonce'] as String?
      ..signedExtensions = (json['signedExtensions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList()
      ..specVersion = json['specVersion'] as String?
      ..tip = json['tip'] as String?
      ..transactionVersion = json['transactionVersion'] as String?
      ..version = json['version'] as int?
      ..payload = json['payload'] as Map<String, dynamic>?;

Map<String, dynamic> _$SignExtrinsicRequestToJson(
        SignExtrinsicRequest instance) =>
    <String, dynamic>{
      'address': instance.address,
      'blockHash': instance.blockHash,
      'blockNumber': instance.blockNumber,
      'era': instance.era,
      'genesisHash': instance.genesisHash,
      'method': instance.method,
      'nonce': instance.nonce,
      'signedExtensions': instance.signedExtensions,
      'specVersion': instance.specVersion,
      'tip': instance.tip,
      'transactionVersion': instance.transactionVersion,
      'version': instance.version,
      'payload': instance.payload,
    };

SignBytesRequest _$SignBytesRequestFromJson(Map<String, dynamic> json) =>
    SignBytesRequest()
      ..address = json['address'] as String?
      ..data = json['data'] as String?
      ..type = json['type'] as String?;

Map<String, dynamic> _$SignBytesRequestToJson(SignBytesRequest instance) =>
    <String, dynamic>{
      'address': instance.address,
      'data': instance.data,
      'type': instance.type,
    };

ExtensionSignResult _$ExtensionSignResultFromJson(Map<String, dynamic> json) =>
    ExtensionSignResult()
      ..id = json['id'] as String?
      ..signature = json['signature'] as String?;

Map<String, dynamic> _$ExtensionSignResultToJson(
        ExtensionSignResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'signature': instance.signature,
    };

DAppConnectParam _$DAppConnectParamFromJson(Map<String, dynamic> json) =>
    DAppConnectParam()
      ..id = json['id'] as String?
      ..url = json['url'] as String?;

Map<String, dynamic> _$DAppConnectParamToJson(DAppConnectParam instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'uosQrParseResultData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UosQrParseResultData _$UosQrParseResultDataFromJson(
        Map<String, dynamic> json) =>
    UosQrParseResultData()
      ..error = json['error'] as String?
      ..signer = json['signer'] as String?
      ..genesisHash = json['genesisHash'] as String?;

Map<String, dynamic> _$UosQrParseResultDataToJson(
        UosQrParseResultData instance) =>
    <String, dynamic>{
      'error': instance.error,
      'signer': instance.signer,
      'genesisHash': instance.genesisHash,
    };

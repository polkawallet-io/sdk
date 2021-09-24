// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'GenerateMnemonicData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenerateMnemonicData _$GenerateMnemonicDataFromJson(Map<String, dynamic> json) {
  return GenerateMnemonicData(
    json['mnemonic'] as String?,
    json['address'] as String,
    json['svg'] as String,
  );
}

Map<String, dynamic> _$GenerateMnemonicDataToJson(
        GenerateMnemonicData instance) =>
    <String, dynamic>{
      'mnemonic': instance.mnemonic,
      'address': instance.address,
      'svg': instance.svg,
    };

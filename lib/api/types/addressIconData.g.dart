// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'addressIconData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressIconDataWithMnemonic _$AddressIconDataWithMnemonicFromJson(
        Map<String, dynamic> json) =>
    AddressIconDataWithMnemonic()
      ..mnemonic = json['mnemonic'] as String?
      ..address = json['address'] as String?
      ..svg = json['svg'] as String?;

Map<String, dynamic> _$AddressIconDataWithMnemonicToJson(
        AddressIconDataWithMnemonic instance) =>
    <String, dynamic>{
      'mnemonic': instance.mnemonic,
      'address': instance.address,
      'svg': instance.svg,
    };

AddressIconData _$AddressIconDataFromJson(Map<String, dynamic> json) =>
    AddressIconData()
      ..address = json['address'] as String?
      ..svg = json['svg'] as String?;

Map<String, dynamic> _$AddressIconDataToJson(AddressIconData instance) =>
    <String, dynamic>{
      'address': instance.address,
      'svg': instance.svg,
    };

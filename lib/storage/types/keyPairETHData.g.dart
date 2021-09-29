// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keyPairETHData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyPairETHData _$KeyPairETHDataFromJson(Map<String, dynamic> json) {
  return KeyPairETHData(
    pubKey: json['pubKey'] as String?,
    address: json['address'] as String?,
    keystore: json['keystore'] as String?,
    name: json['name'] as String?,
    icon: json['icon'] as String?,
  );
}

Map<String, dynamic> _$KeyPairETHDataToJson(KeyPairETHData instance) =>
    <String, dynamic>{
      'pubKey': instance.pubKey,
      'address': instance.address,
      'keystore': instance.keystore,
      'name': instance.name,
      'icon': instance.name,
    };

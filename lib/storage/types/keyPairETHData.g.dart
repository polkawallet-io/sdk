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
    observation: json['observation'] as bool?,
    memo: json['memo'] as String?,
  )
    ..encoded = json['encoded'] as String?
    ..encoding = json['encoding'] as Map<String, dynamic>?
    ..meta = json['meta'] as Map<String, dynamic>?
    ..indexInfo = json['indexInfo'] as Map<String, dynamic>?;
}

Map<String, dynamic> _$KeyPairETHDataToJson(KeyPairETHData instance) =>
    <String, dynamic>{
      'encoded': instance.encoded,
      'encoding': instance.encoding,
      'meta': instance.meta,
      'indexInfo': instance.indexInfo,
      'pubKey': instance.pubKey,
      'address': instance.address,
      'keystore': instance.keystore,
      'name': instance.name,
      'icon': instance.icon,
      'observation': instance.observation,
      'memo': instance.memo,
    };

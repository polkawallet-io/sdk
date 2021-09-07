// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keyPairData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyPairData _$KeyPairDataFromJson(Map<String, dynamic> json) => KeyPairData()
  ..name = json['name'] as String?
  ..address = json['address'] as String?
  ..encoded = json['encoded'] as String?
  ..pubKey = json['pubKey'] as String?
  ..encoding = json['encoding'] as Map<String, dynamic>?
  ..meta = json['meta'] as Map<String, dynamic>?
  ..memo = json['memo'] as String?
  ..observation = json['observation'] as bool?
  ..icon = json['icon'] as String?
  ..indexInfo = json['indexInfo'] as Map<String, dynamic>?;

Map<String, dynamic> _$KeyPairDataToJson(KeyPairData instance) =>
    <String, dynamic>{
      'name': instance.name,
      'address': instance.address,
      'encoded': instance.encoded,
      'pubKey': instance.pubKey,
      'encoding': instance.encoding,
      'meta': instance.meta,
      'memo': instance.memo,
      'observation': instance.observation,
      'icon': instance.icon,
      'indexInfo': instance.indexInfo,
    };

SeedBackupData _$SeedBackupDataFromJson(Map<String, dynamic> json) =>
    SeedBackupData()
      ..type = json['type'] as String?
      ..seed = json['seed'] as String?
      ..error = json['error'] as String?;

Map<String, dynamic> _$SeedBackupDataToJson(SeedBackupData instance) =>
    <String, dynamic>{
      'type': instance.type,
      'seed': instance.seed,
      'error': instance.error,
    };

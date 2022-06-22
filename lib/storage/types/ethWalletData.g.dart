// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ethWalletData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EthWalletData _$EthWalletDataFromJson(Map<String, dynamic> json) =>
    EthWalletData()
      ..address = json['address'] as String?
      ..name = json['name'] as String?
      ..id = json['id'] as String?
      ..version = json['version'] as int?
      ..crypto = json['crypto'] as Map<String, dynamic>?
      ..memo = json['memo'] as String?
      ..observation = json['observation'] as bool?
      ..icon = json['icon'] as String?;

Map<String, dynamic> _$EthWalletDataToJson(EthWalletData instance) =>
    <String, dynamic>{
      'address': instance.address,
      'name': instance.name,
      'id': instance.id,
      'version': instance.version,
      'crypto': instance.crypto,
      'memo': instance.memo,
      'observation': instance.observation,
      'icon': instance.icon,
    };

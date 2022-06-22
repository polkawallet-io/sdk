// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'networkStateData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkStateData _$NetworkStateDataFromJson(Map<String, dynamic> json) =>
    NetworkStateData()
      ..ss58Format = json['ss58Format'] as int?
      ..tokenDecimals = (json['tokenDecimals'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList()
      ..tokenSymbol = (json['tokenSymbol'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList()
      ..name = json['name'] as String?
      ..genesisHash = json['genesisHash'] as String?;

Map<String, dynamic> _$NetworkStateDataToJson(NetworkStateData instance) =>
    <String, dynamic>{
      'ss58Format': instance.ss58Format,
      'tokenDecimals': instance.tokenDecimals,
      'tokenSymbol': instance.tokenSymbol,
      'name': instance.name,
      'genesisHash': instance.genesisHash,
    };

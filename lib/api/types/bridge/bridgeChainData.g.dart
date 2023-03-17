// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bridgeChainData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BridgeChainData _$BridgeChainDataFromJson(Map<String, dynamic> json) =>
    BridgeChainData(
      id: json['id'] as String,
      display: json['display'] as String,
      icon: json['icon'] as String,
      paraChainId: json['paraChainId'] as int,
      ss58Prefix: json['ss58Prefix'] as int,
    );

Map<String, dynamic> _$BridgeChainDataToJson(BridgeChainData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'display': instance.display,
      'icon': instance.icon,
      'paraChainId': instance.paraChainId,
      'ss58Prefix': instance.ss58Prefix,
    };

BridgeRouteData _$BridgeRouteDataFromJson(Map<String, dynamic> json) =>
    BridgeRouteData(
      from: json['from'] as String,
      to: json['to'] as String,
      token: json['token'] as String,
    );

Map<String, dynamic> _$BridgeRouteDataToJson(BridgeRouteData instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'token': instance.token,
    };

BridgeNetworkProperties _$BridgeNetworkPropertiesFromJson(
        Map<String, dynamic> json) =>
    BridgeNetworkProperties(
      ss58Format: json['ss58Format'] as int,
      tokenDecimals: (json['tokenDecimals'] as List<dynamic>)
          .map((e) => e as int)
          .toList(),
      tokenSymbol: (json['tokenSymbol'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$BridgeNetworkPropertiesToJson(
        BridgeNetworkProperties instance) =>
    <String, dynamic>{
      'ss58Format': instance.ss58Format,
      'tokenDecimals': instance.tokenDecimals,
      'tokenSymbol': instance.tokenSymbol,
    };

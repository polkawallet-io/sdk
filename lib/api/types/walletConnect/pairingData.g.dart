// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pairingData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WCPairingData _$WCPairingDataFromJson(Map<String, dynamic> json) =>
    WCPairingData()
      ..id = json['id'] as int?
      ..params = json['params'] == null
          ? null
          : WCPairingParamsData.fromJson(
              json['params'] as Map<String, dynamic>);

Map<String, dynamic> _$WCPairingDataToJson(WCPairingData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'params': instance.params?.toJson(),
    };

WCPairingParamsData _$WCPairingParamsDataFromJson(Map<String, dynamic> json) =>
    WCPairingParamsData()
      ..id = json['id'] as int?
      ..expiry = json['expiry'] as int?
      ..relays = (json['relays'] as List<dynamic>?)
          ?.map((e) => WCRelayProtocol.fromJson(e as Map<String, dynamic>))
          .toList()
      ..proposer = json['proposer'] == null
          ? null
          : WCProposerInfo.fromJson(json['proposer'] as Map<String, dynamic>)
      ..requiredNamespaces =
          (json['requiredNamespaces'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
            k, WCPermissionNamespaces.fromJson(e as Map<String, dynamic>)),
      )
      ..pairingTopic = json['pairingTopic'] as String?;

Map<String, dynamic> _$WCPairingParamsDataToJson(
        WCPairingParamsData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'expiry': instance.expiry,
      'relays': instance.relays?.map((e) => e.toJson()).toList(),
      'proposer': instance.proposer?.toJson(),
      'requiredNamespaces':
          instance.requiredNamespaces?.map((k, e) => MapEntry(k, e.toJson())),
      'pairingTopic': instance.pairingTopic,
    };

WCRelayProtocol _$WCRelayProtocolFromJson(Map<String, dynamic> json) =>
    WCRelayProtocol()
      ..protocol = json['protocol'] as String?
      ..data = json['data'] as String?;

Map<String, dynamic> _$WCRelayProtocolToJson(WCRelayProtocol instance) =>
    <String, dynamic>{
      'protocol': instance.protocol,
      'data': instance.data,
    };

WCProposerInfo _$WCProposerInfoFromJson(Map<String, dynamic> json) =>
    WCProposerInfo()
      ..publicKey = json['publicKey'] as String?
      ..metadata = json['metadata'] == null
          ? null
          : WCProposerMeta.fromJson(json['metadata'] as Map<String, dynamic>);

Map<String, dynamic> _$WCProposerInfoToJson(WCProposerInfo instance) =>
    <String, dynamic>{
      'publicKey': instance.publicKey,
      'metadata': instance.metadata?.toJson(),
    };

WCProposerMeta _$WCProposerMetaFromJson(Map<String, dynamic> json) =>
    WCProposerMeta()
      ..name = json['name'] as String?
      ..description = json['description'] as String?
      ..url = json['url'] as String?
      ..icons =
          (json['icons'] as List<dynamic>?)?.map((e) => e as String).toList();

Map<String, dynamic> _$WCProposerMetaToJson(WCProposerMeta instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'url': instance.url,
      'icons': instance.icons,
    };

WCSessionDataV2 _$WCSessionDataV2FromJson(Map<String, dynamic> json) =>
    WCSessionDataV2()
      ..topic = json['topic'] as String?
      ..peerMeta = json['peerMeta'] == null
          ? null
          : WCProposerMeta.fromJson(json['peerMeta'] as Map<String, dynamic>)
      ..namespaces = (json['namespaces'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
            k, WCPermissionNamespaces.fromJson(e as Map<String, dynamic>)),
      )
      ..expiry = json['expiry'] as int?;

Map<String, dynamic> _$WCSessionDataV2ToJson(WCSessionDataV2 instance) =>
    <String, dynamic>{
      'topic': instance.topic,
      'peerMeta': instance.peerMeta,
      'namespaces': instance.namespaces,
      'expiry': instance.expiry,
    };

WCPermissionNamespaces _$WCPermissionNamespacesFromJson(
        Map<String, dynamic> json) =>
    WCPermissionNamespaces()
      ..chains =
          (json['chains'] as List<dynamic>?)?.map((e) => e as String).toList()
      ..accounts =
          (json['accounts'] as List<dynamic>?)?.map((e) => e as String).toList()
      ..methods =
          (json['methods'] as List<dynamic>?)?.map((e) => e as String).toList()
      ..events =
          (json['events'] as List<dynamic>?)?.map((e) => e as String).toList();

Map<String, dynamic> _$WCPermissionNamespacesToJson(
        WCPermissionNamespaces instance) =>
    <String, dynamic>{
      'chains': instance.chains,
      'accounts': instance.accounts,
      'methods': instance.methods,
      'events': instance.events,
    };

import 'package:json_annotation/json_annotation.dart';

part 'pairingData.g.dart';

@JsonSerializable(explicitToJson: true)
class WCPairingData extends _WCPairingData {
  static WCPairingData fromJson(Map json) =>
      _$WCPairingDataFromJson(json as Map<String, dynamic>);
  Map toJson() => _$WCPairingDataToJson(this);
}

abstract class _WCPairingData {
  int? id;
  WCPairingParamsData? params;
}

@JsonSerializable(explicitToJson: true)
class WCPairingParamsData extends _WCPairingParamsData {
  static WCPairingParamsData fromJson(Map json) =>
      _$WCPairingParamsDataFromJson(json as Map<String, dynamic>);
  Map toJson() => _$WCPairingParamsDataToJson(this);
}

abstract class _WCPairingParamsData {
  int? id;
  int? expiry;
  List<WCRelayProtocol>? relays;
  WCProposerInfo? proposer;
  Map<String, WCPermissionNamespaces>? requiredNamespaces;
  String? pairingTopic;
}

@JsonSerializable(explicitToJson: true)
class WCRelayProtocol extends _WCRelayProtocol {
  static WCRelayProtocol fromJson(Map json) =>
      _$WCRelayProtocolFromJson(json as Map<String, dynamic>);
  Map toJson() => _$WCRelayProtocolToJson(this);
}

abstract class _WCRelayProtocol {
  String? protocol;
  String? data;
}

@JsonSerializable(explicitToJson: true)
class WCProposerInfo extends _WCProposerInfo {
  static WCProposerInfo fromJson(Map json) =>
      _$WCProposerInfoFromJson(json as Map<String, dynamic>);
  Map toJson() => _$WCProposerInfoToJson(this);
}

abstract class _WCProposerInfo {
  String? publicKey;
  WCProposerMeta? metadata;
}

@JsonSerializable()
class WCProposerMeta extends _WCProposerMeta {
  static WCProposerMeta fromJson(Map json) =>
      _$WCProposerMetaFromJson(json as Map<String, dynamic>);
  Map toJson() => _$WCProposerMetaToJson(this);
}

abstract class _WCProposerMeta {
  String? name;
  String? description;
  String? url;
  List<String>? icons;
}

@JsonSerializable()
class WCSessionDataV2 extends _WCSessionDataV2 {
  static WCSessionDataV2 fromJson(Map json) =>
      _$WCSessionDataV2FromJson(json as Map<String, dynamic>);
  Map toJson() => _$WCSessionDataV2ToJson(this);
}

abstract class _WCSessionDataV2 {
  String? topic;
  WCProposerMeta? peerMeta;
  Map<String, WCPermissionNamespaces>? namespaces;
  int? expiry;
}

@JsonSerializable()
class WCPermissionNamespaces extends _WCPermissionNamespaces {
  static WCPermissionNamespaces fromJson(Map json) =>
      _$WCPermissionNamespacesFromJson(json as Map<String, dynamic>);
  Map toJson() => _$WCPermissionNamespacesToJson(this);
}

abstract class _WCPermissionNamespaces {
  List<String>? chains;
  List<String>? accounts;
  List<String>? methods;
  List<String>? events;
}

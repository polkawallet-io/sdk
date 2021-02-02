import 'package:json_annotation/json_annotation.dart';

part 'pairingData.g.dart';

@JsonSerializable(explicitToJson: true)
class WCPairingData extends _WCPairingData {
  static WCPairingData fromJson(Map json) => _$WCPairingDataFromJson(json);
  Map toJson() => _$WCPairingDataToJson(this);
}

abstract class _WCPairingData {
  String topic;
  Map relay;
  WCProposerInfo proposer;
  String signal;
  List<String> permissions;
  int ttl;
}

@JsonSerializable(explicitToJson: true)
class WCProposerInfo extends _WCProposerInfo {
  static WCProposerInfo fromJson(Map json) => _$WCProposerInfoFromJson(json);
  Map toJson() => _$WCProposerInfoToJson(this);
}

abstract class _WCProposerInfo {
  String publicKey;
  WCProposerMeta metadata;
}

@JsonSerializable()
class WCProposerMeta extends _WCProposerMeta {
  static WCProposerMeta fromJson(Map json) => _$WCProposerMetaFromJson(json);
  Map toJson() => _$WCProposerMetaToJson(this);
}

abstract class _WCProposerMeta {
  String name;
  String description;
  String url;
  List<String> icons;
}

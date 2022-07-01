import 'package:json_annotation/json_annotation.dart';

part 'bridgeChainData.g.dart';

@JsonSerializable()
class BridgeChainData {
  String id;
  String display;
  String icon;
  int paraChainId;
  int ss58Prefix;
  BridgeChainData({
    required this.id,
    required this.display,
    required this.icon,
    required this.paraChainId,
    required this.ss58Prefix,
  });

  static BridgeChainData fromJson(Map<String, dynamic> json) =>
      _$BridgeChainDataFromJson(json);
  Map<String, dynamic> toJson() => _$BridgeChainDataToJson(this);
}

@JsonSerializable()
class BridgeRouteData {
  String from;
  String to;
  String token;
  BridgeRouteData({
    required this.from,
    required this.to,
    required this.token,
  });

  static BridgeRouteData fromJson(Map<String, dynamic> json) =>
      _$BridgeRouteDataFromJson(json);
  Map<String, dynamic> toJson() => _$BridgeRouteDataToJson(this);
}

@JsonSerializable()
class BridgeNetworkProperties {
  int ss58Format;
  List<int> tokenDecimals;
  List<String> tokenSymbol;
  BridgeNetworkProperties({
    required this.ss58Format,
    required this.tokenDecimals,
    required this.tokenSymbol,
  });

  static BridgeNetworkProperties fromJson(Map<String, dynamic> json) =>
      _$BridgeNetworkPropertiesFromJson(json);
  Map<String, dynamic> toJson() => _$BridgeNetworkPropertiesToJson(this);
}

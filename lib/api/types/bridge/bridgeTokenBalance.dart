import 'package:json_annotation/json_annotation.dart';

part 'bridgeTokenBalance.g.dart';

@JsonSerializable()
class BridgeTokenBalance {
  String token;
  String free;
  String available;
  String locked;
  String reserved;
  int decimals;
  BridgeTokenBalance({
    required this.token,
    required this.free,
    required this.available,
    required this.locked,
    required this.reserved,
    required this.decimals,
  });

  static BridgeTokenBalance fromJson(Map<String, dynamic> json) =>
      _$BridgeTokenBalanceFromJson(json);
  Map<String, dynamic> toJson() => _$BridgeTokenBalanceToJson(this);
}

@JsonSerializable()
class BridgeAmountInputConfig {
  String token;
  String from;
  String to;
  String address;
  String minInput;
  String maxInput;
  BridgeAmountInputConfig({
    required this.token,
    required this.from,
    required this.to,
    required this.address,
    required this.minInput,
    required this.maxInput,
  });

  static BridgeAmountInputConfig fromJson(Map<String, dynamic> json) =>
      _$BridgeAmountInputConfigFromJson(json);
  Map<String, dynamic> toJson() => _$BridgeAmountInputConfigToJson(this);
}

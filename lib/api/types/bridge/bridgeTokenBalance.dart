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
  BridgeDestFeeData destFee;
  String estimateFee;
  BridgeAmountInputConfig({
    required this.token,
    required this.from,
    required this.to,
    required this.address,
    required this.minInput,
    required this.maxInput,
    required this.destFee,
    required this.estimateFee,
  });

  static BridgeAmountInputConfig fromJson(Map<String, dynamic> json) =>
      _$BridgeAmountInputConfigFromJson(json);
  Map<String, dynamic> toJson() => _$BridgeAmountInputConfigToJson(this);
}

@JsonSerializable()
class BridgeDestFeeData {
  String token;
  String amount;
  int decimals;
  BridgeDestFeeData({
    required this.token,
    required this.amount,
    required this.decimals,
  });

  static BridgeDestFeeData fromJson(Map<String, dynamic> json) =>
      _$BridgeDestFeeDataFromJson(json);
  Map<String, dynamic> toJson() => _$BridgeDestFeeDataToJson(this);
}

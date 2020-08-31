import 'package:json_annotation/json_annotation.dart';

part 'networkStateData.g.dart';

@JsonSerializable()
class NetworkStateData extends _NetworkStateData {
  static NetworkStateData fromJson(Map<String, dynamic> json) =>
      _$NetworkStateDataFromJson(json);
  static Map<String, dynamic> toJson(NetworkStateData net) =>
      _$NetworkStateDataToJson(net);
}

abstract class _NetworkStateData {
  int ss58Format = 0;
  int tokenDecimals = 0;
  String tokenSymbol = '';
  String name = '';
}

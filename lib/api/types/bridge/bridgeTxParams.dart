import 'package:json_annotation/json_annotation.dart';

part 'bridgeTxParams.g.dart';

@JsonSerializable()
class BridgeTxParams {
  String module;
  String call;
  List params;
  BridgeTxParams({
    required this.module,
    required this.call,
    required this.params,
  });

  static BridgeTxParams fromJson(Map<String, dynamic> json) =>
      _$BridgeTxParamsFromJson(json);
  Map<String, dynamic> toJson() => _$BridgeTxParamsToJson(this);
}

import 'package:json_annotation/json_annotation.dart';

part 'networkParams.g.dart';

@JsonSerializable()
class NetworkParams extends _NetworkParams {
  static NetworkParams fromJson(Map<String, dynamic> json) =>
      _$NetworkParamsFromJson(json);
  static Map<String, dynamic> toJson(NetworkParams ins) =>
      _$NetworkParamsToJson(ins);
}

abstract class _NetworkParams {
  String name = '';
  String endpoint = '';
  int ss58 = 0;
}

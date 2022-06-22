import 'package:json_annotation/json_annotation.dart';

part 'ethWalletData.g.dart';

@JsonSerializable()
class EthWalletData extends _EthWalletData {
  static EthWalletData fromJson(Map json) =>
      _$EthWalletDataFromJson(Map<String, dynamic>.from(json));
  Map<String, dynamic> toJson() => _$EthWalletDataToJson(this);
}

abstract class _EthWalletData {
  String? address;
  String? name;
  String? id;
  int? version;

  Map<String, dynamic>? crypto = Map<String, dynamic>();

  /// for contacts
  String? memo;
  bool? observation = false;

  /// address avatar in svg format
  String? icon;
}

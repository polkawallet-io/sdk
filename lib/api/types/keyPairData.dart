import 'package:json_annotation/json_annotation.dart';

part 'keyPairData.g.dart';

@JsonSerializable()
class KeyPairData extends _KeyPairData {
  static KeyPairData fromJson(Map<String, dynamic> json) =>
      _$KeyPairDataFromJson(json);
  static Map<String, dynamic> toJson(KeyPairData acc) =>
      _$KeyPairDataToJson(acc);
}

abstract class _KeyPairData {
  String name = '';
  String address = '';
  String encoded = '';
  String pubKey = '';

  Map<String, dynamic> encoding = Map<String, dynamic>();
  Map<String, dynamic> meta = Map<String, dynamic>();

  String memo = '';
  bool observation = false;
}

@JsonSerializable()
class SeedBackupData extends _SeedBackupData {
  static SeedBackupData fromJson(Map<String, dynamic> json) =>
      _$SeedBackupDataFromJson(json);
  static Map<String, dynamic> toJson(SeedBackupData acc) =>
      _$SeedBackupDataToJson(acc);
}

abstract class _SeedBackupData {
  String type;
  String seed;
  String error;
}

import 'package:json_annotation/json_annotation.dart';

part 'keyPairETHData.g.dart';

@JsonSerializable()
class KeyPairETHData {
  String? pubKey;
  String? address;
  String? keystore;
  String? name;

  KeyPairETHData({this.pubKey, this.address, this.keystore, this.name});

  factory KeyPairETHData.fromJson(Map<String, dynamic> json) =>
      _$KeyPairETHDataFromJson(json);

  Map<String, dynamic> toJson() => _$KeyPairETHDataToJson(this);
}

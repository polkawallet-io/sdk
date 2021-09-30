import 'package:json_annotation/json_annotation.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';

part 'keyPairETHData.g.dart';

@JsonSerializable()
class KeyPairETHData extends KeyPairData {
  String? pubKey;
  String? address;
  String? keystore;
  String? name;
  String? icon;
  bool? observation = false;
  String? memo;

  KeyPairETHData(
      {this.pubKey,
      this.address,
      this.keystore,
      this.name,
      this.icon,
      this.observation,
      this.memo});

  factory KeyPairETHData.fromJson(Map<String, dynamic> json) =>
      _$KeyPairETHDataFromJson(json);

  Map<String, dynamic> toJson() => _$KeyPairETHDataToJson(this);
}

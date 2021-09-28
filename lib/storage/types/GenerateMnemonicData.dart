import 'package:json_annotation/json_annotation.dart';

part 'GenerateMnemonicData.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()
class GenerateMnemonicData {
  final String? mnemonic;
  final String? address;
  final String? svg;
  final String? path;

  GenerateMnemonicData(this.mnemonic, this.address, this.svg, this.path);

  //反序列化,factory *.fromJson(Map<String, dynamic> json) =>_$*FromJson(json);
  factory GenerateMnemonicData.fromJson(Map<String, dynamic> json) =>
      _$GenerateMnemonicDataFromJson(json);

  //序列化,Map<String, dynamic> toJson() => _$*ToJson(this);
  Map<String, dynamic> toJson() => _$GenerateMnemonicDataToJson(this);
}

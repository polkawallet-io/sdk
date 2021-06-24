import 'package:json_annotation/json_annotation.dart';

part 'fundData.g.dart';

@JsonSerializable()
class FundData extends _FundData {
  static FundData fromJson(Map json) => _$FundDataFromJson(json);
  static Map toJson(FundData data) => _$FundDataToJson(data);
}

abstract class _FundData {
  String paraId;
  dynamic cap;
  dynamic value;
  dynamic end;
  int firstSlot;
  int lastSlot;
  bool isWinner;
  bool isCapped;
  bool isEnded;
}

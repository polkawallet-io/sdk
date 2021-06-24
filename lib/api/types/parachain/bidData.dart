import 'package:json_annotation/json_annotation.dart';

part 'bidData.g.dart';

@JsonSerializable()
class BidData extends _BidData {
  static BidData fromJson(Map json) => _$BidDataFromJson(json);
  static Map toJson(BidData data) => _$BidDataToJson(data);
}

abstract class _BidData {
  String paraId;
  int firstSlot;
  int lastSlot;
  bool isCrowdloan;
  dynamic value;
}

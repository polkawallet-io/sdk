// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bidData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BidData _$BidDataFromJson(Map<String, dynamic> json) => BidData()
  ..paraId = json['paraId'] as String?
  ..firstSlot = json['firstSlot'] as int?
  ..lastSlot = json['lastSlot'] as int?
  ..isCrowdloan = json['isCrowdloan'] as bool?
  ..value = json['value'];

Map<String, dynamic> _$BidDataToJson(BidData instance) => <String, dynamic>{
      'paraId': instance.paraId,
      'firstSlot': instance.firstSlot,
      'lastSlot': instance.lastSlot,
      'isCrowdloan': instance.isCrowdloan,
      'value': instance.value,
    };

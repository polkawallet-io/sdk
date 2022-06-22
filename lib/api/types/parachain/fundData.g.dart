// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fundData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FundData _$FundDataFromJson(Map<String, dynamic> json) => FundData()
  ..paraId = json['paraId'] as String
  ..cap = json['cap']
  ..value = json['value']
  ..end = json['end']
  ..firstSlot = json['firstSlot'] as int
  ..lastSlot = json['lastSlot'] as int
  ..isWinner = json['isWinner'] as bool
  ..isCapped = json['isCapped'] as bool
  ..isEnded = json['isEnded'] as bool;

Map<String, dynamic> _$FundDataToJson(FundData instance) => <String, dynamic>{
      'paraId': instance.paraId,
      'cap': instance.cap,
      'value': instance.value,
      'end': instance.end,
      'firstSlot': instance.firstSlot,
      'lastSlot': instance.lastSlot,
      'isWinner': instance.isWinner,
      'isCapped': instance.isCapped,
      'isEnded': instance.isEnded,
    };

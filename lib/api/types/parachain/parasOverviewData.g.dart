// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parasOverviewData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParasOverviewData _$ParasOverviewDataFromJson(Map<String, dynamic> json) =>
    ParasOverviewData()
      ..parasCount = json['parasCount'] as int
      ..currentLease = json['currentLease'] as int
      ..leaseLength = json['leaseLength'] as int
      ..leaseProgress = json['leaseProgress'] as int;

Map<String, dynamic> _$ParasOverviewDataToJson(ParasOverviewData instance) =>
    <String, dynamic>{
      'parasCount': instance.parasCount,
      'currentLease': instance.currentLease,
      'leaseLength': instance.leaseLength,
      'leaseProgress': instance.leaseProgress,
    };

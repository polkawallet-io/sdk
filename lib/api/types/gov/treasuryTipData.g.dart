// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'treasuryTipData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TreasuryTipData _$TreasuryTipDataFromJson(Map<String, dynamic> json) {
  return TreasuryTipData()
    ..hash = json['hash'] as String?
    ..reason = json['reason'] as String?
    ..who = json['who'] as String?
    ..closes = json['closes']
    ..finder = json['finder'] as String?
    ..deposit = json['deposit']
    ..tips = (json['tips'] as List<dynamic>?)
        ?.map((e) => TreasuryTipItemData.fromJson(e as Map<String, dynamic>))
        .toList();
}

TreasuryTipItemData _$TreasuryTipItemDataFromJson(Map<String, dynamic> json) {
  return TreasuryTipItemData()
    ..address = json['address'] as String?
    ..value = json['value'];
}

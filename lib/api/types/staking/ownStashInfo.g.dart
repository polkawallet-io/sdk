// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ownStashInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OwnStashInfoData _$OwnStashInfoDataFromJson(Map<String, dynamic> json) {
  return OwnStashInfoData()
    ..account = json['account'] == null
        ? null
        : LedgerInfoData.fromJson(json['account'] as Map<String, dynamic>)
    ..controllerId = json['controllerId'] as String?
    ..destination = json['destination'] as String?
    ..destinationId = json['destinationId'] as int?
    ..exposure = json['exposure'] as Map<String, dynamic>?
    ..hexSessionIdNext = json['hexSessionIdNext'] as String?
    ..hexSessionIdQueue = json['hexSessionIdQueue'] as String?
    ..isOwnController = json['isOwnController'] as bool?
    ..isOwnStash = json['isOwnStash'] as bool?
    ..isStashNominating = json['isStashNominating'] as bool?
    ..isStashValidating = json['isStashValidating'] as bool?
    ..nominating =
        (json['nominating'] as List<dynamic>?)?.map((e) => e as String).toList()
    ..sessionIds =
        (json['sessionIds'] as List<dynamic>?)?.map((e) => e as String).toList()
    ..stakingLedger = json['stakingLedger'] as Map<String, dynamic>?
    ..stashId = json['stashId'] as String?
    ..validatorPrefs = json['validatorPrefs'] as Map<String, dynamic>?
    ..inactives = json['inactives'] == null
        ? null
        : NomineesInfoData.fromJson(json['inactives'] as Map<String, dynamic>)
    ..unbondings = json['unbondings'] as Map<String, dynamic>?;
}

NomineesInfoData _$NomineesInfoDataFromJson(Map<String, dynamic> json) {
  return NomineesInfoData()
    ..nomsActive =
        (json['nomsActive'] as List<dynamic>?)?.map((e) => e as String).toList()
    ..nomsChilled = (json['nomsChilled'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList()
    ..nomsInactive = (json['nomsInactive'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList()
    ..nomsOver =
        (json['nomsOver'] as List<dynamic>?)?.map((e) => e as String).toList()
    ..nomsWaiting = (json['nomsWaiting'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList();
}

LedgerInfoData _$LedgerInfoDataFromJson(Map<String, dynamic> json) {
  return LedgerInfoData()
    ..accountId = json['accountId'] as String?
    ..controllerId = json['controllerId'] as String?
    ..stashId = json['stashId'] as String?
    ..exposure = json['exposure'] as Map<String, dynamic>?
    ..stakingLedger = json['stakingLedger'] as Map<String, dynamic>?
    ..validatorPrefs = json['validatorPrefs'] as Map<String, dynamic>?
    ..redeemable = json['redeemable'];
}

UnbondingInfoData _$UnbondingInfoDataFromJson(Map<String, dynamic> json) {
  return UnbondingInfoData()
    ..mapped = json['mapped'] as List<dynamic>?
    ..total = json['total'];
}

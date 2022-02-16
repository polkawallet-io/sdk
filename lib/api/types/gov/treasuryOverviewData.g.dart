// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'treasuryOverviewData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TreasuryOverviewData _$TreasuryOverviewDataFromJson(Map<String, dynamic> json) {
  return TreasuryOverviewData()
    ..balance = json['balance'] as String?
    ..spendable = json['spendable'] as String?
    ..burn = json['burn'] as String?
    ..approved = json['approved'] as String?
    ..proposalCount = json['proposalCount'] as String?
    ..proposals = (json['proposals'] as List<dynamic>?)
        ?.map((e) => SpendProposalData.fromJson(e as Map<String, dynamic>))
        .toList()
    ..approvals = (json['approvals'] as List<dynamic>?)
        ?.map((e) => SpendProposalData.fromJson(e as Map<String, dynamic>))
        .toList();
}

Map<String, dynamic> _$TreasuryOverviewDataToJson(
        TreasuryOverviewData instance) =>
    <String, dynamic>{
      'balance': instance.balance,
      'spendable': instance.spendable,
      'burn': instance.burn,
      'approved': instance.approved,
      'proposalCount': instance.proposalCount,
      'proposals': instance.proposals,
      'approvals': instance.approvals,
    };

SpendProposalData _$SpendProposalDataFromJson(Map<String, dynamic> json) {
  return SpendProposalData()
    ..id = json['id'] as String?
    ..isApproval = json['isApproval'] as bool?
    ..council = (json['council'] as List<dynamic>?)
        ?.map((e) => CouncilMotionData.fromJson(e as Map<String, dynamic>))
        .toList()
    ..proposal = json['proposal'] == null
        ? null
        : SpendProposalDetailData.fromJson(
            json['proposal'] as Map<String, dynamic>);
}

CouncilMotionData _$CouncilMotionDataFromJson(Map<String, dynamic> json) {
  return CouncilMotionData()
    ..hash = json['hash'] as String?
    ..proposal = json['proposal'] == null
        ? null
        : CouncilProposalData.fromJson(json['proposal'] as Map<String, dynamic>)
    ..votes = json['votes'] == null
        ? null
        : CouncilProposalVotesData.fromJson(
            json['votes'] as Map<String, dynamic>);
}

CouncilProposalData _$CouncilProposalDataFromJson(Map<String, dynamic> json) {
  return CouncilProposalData()
    ..callIndex = json['callIndex'] as String?
    ..method = json['method'] as String?
    ..section = json['section'] as String?
    ..args = json['args'] as List<dynamic>?
    ..meta = json['meta'] == null
        ? null
        : ProposalMetaData.fromJson(json['meta'] as Map<String, dynamic>);
}

ProposalMetaData _$ProposalMetaDataFromJson(Map<String, dynamic> json) {
  return ProposalMetaData()
    ..name = json['name'] as String?
    ..documentation = json['documentation'] as String?
    ..args = (json['args'] as List<dynamic>?)
        ?.map((e) => ProposalArgsItemData.fromJson(e as Map<String, dynamic>))
        .toList();
}

ProposalArgsItemData _$ProposalArgsItemDataFromJson(Map<String, dynamic> json) {
  return ProposalArgsItemData()
    ..name = json['name'] as String?
    ..type = json['type'] as String?;
}

CouncilProposalVotesData _$CouncilProposalVotesDataFromJson(
    Map<String, dynamic> json) {
  return CouncilProposalVotesData()
    ..index = json['index'] as int?
    ..threshold = json['threshold'] as int?
    ..ayes = (json['ayes'] as List<dynamic>?)?.map((e) => e as String).toList()
    ..nays = (json['nays'] as List<dynamic>?)?.map((e) => e as String).toList()
    ..end = json['end'];
}

SpendProposalDetailData _$SpendProposalDetailDataFromJson(
    Map<String, dynamic> json) {
  return SpendProposalDetailData()
    ..proposer = json['proposer'] as String?
    ..beneficiary = json['beneficiary'] as String?
    ..value = json['value']
    ..bond = json['bond'];
}

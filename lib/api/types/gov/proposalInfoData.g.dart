// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proposalInfoData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProposalInfoData _$ProposalInfoDataFromJson(Map<String, dynamic> json) =>
    ProposalInfoData()
      ..balance = json['balance']
      ..seconds =
          (json['seconds'] as List<dynamic>?)?.map((e) => e as String).toList()
      ..image = json['image'] == null
          ? null
          : ProposalImageData.fromJson(json['image'] as Map<String, dynamic>)
      ..imageHash = json['imageHash'] as String?
      ..proposer = json['proposer'] as String?
      ..index = json['index'];

Map<String, dynamic> _$ProposalInfoDataToJson(ProposalInfoData instance) =>
    <String, dynamic>{
      'balance': instance.balance,
      'seconds': instance.seconds,
      'image': instance.image,
      'imageHash': instance.imageHash,
      'proposer': instance.proposer,
      'index': instance.index,
    };

ProposalImageData _$ProposalImageDataFromJson(Map<String, dynamic> json) =>
    ProposalImageData()
      ..balance = json['balance']
      ..at = json['at']
      ..proposer = json['proposer'] as String?
      ..proposal = json['proposal'] == null
          ? null
          : CouncilProposalData.fromJson(
              json['proposal'] as Map<String, dynamic>);

Map<String, dynamic> _$ProposalImageDataToJson(ProposalImageData instance) =>
    <String, dynamic>{
      'balance': instance.balance,
      'at': instance.at,
      'proposer': instance.proposer,
      'proposal': instance.proposal,
    };

import 'package:json_annotation/json_annotation.dart';

part 'treasuryOverviewData.g.dart';

@JsonSerializable()
class TreasuryOverviewData extends _TreasuryOverviewData {
  static TreasuryOverviewData fromJson(Map<String, dynamic> json) =>
      _$TreasuryOverviewDataFromJson(json);
  Map<String, dynamic> toJson() => _$TreasuryOverviewDataToJson(this);
}

abstract class _TreasuryOverviewData {
  String? balance;
  String? spendable;
  String? burn;
  String? approved;
  String? proposalCount;
  List<SpendProposalData>? proposals;
  List<SpendProposalData>? approvals;
}

@JsonSerializable()
class SpendProposalData extends _SpendProposalData {
  static SpendProposalData fromJson(Map<String, dynamic> json) =>
      _$SpendProposalDataFromJson(json);
  Map<String, dynamic> toJson() => _$SpendProposalDataToJson(this);
}

abstract class _SpendProposalData {
  String? id;
  bool? isApproval;
  List<CouncilMotionData>? council;
  SpendProposalDetailData? proposal;
}

@JsonSerializable()
class CouncilMotionData extends _CouncilMotionData {
  static CouncilMotionData fromJson(Map<String, dynamic> json) =>
      _$CouncilMotionDataFromJson(json);
  Map<String, dynamic> toJson() => _$CouncilMotionDataToJson(this);
}

abstract class _CouncilMotionData {
  String? hash;
  CouncilProposalData? proposal;
  CouncilProposalVotesData? votes;
}

@JsonSerializable()
class CouncilProposalData extends _CouncilProposalData {
  static CouncilProposalData fromJson(Map<String, dynamic> json) =>
      _$CouncilProposalDataFromJson(json);
  Map<String, dynamic> toJson() => _$CouncilProposalDataToJson(this);
}

abstract class _CouncilProposalData {
  String? callIndex;
  String? method;
  String? section;
  List? args;
  ProposalMetaData? meta;
}

@JsonSerializable()
class ProposalMetaData extends _ProposalMetaData {
  static ProposalMetaData fromJson(Map<String, dynamic> json) =>
      _$ProposalMetaDataFromJson(json);
  Map<String, dynamic> toJson() => _$ProposalMetaDataToJson(this);
}

abstract class _ProposalMetaData {
  String? name;
  String? documentation;
  List<ProposalArgsItemData>? args;
}

@JsonSerializable()
class ProposalArgsItemData extends _ProposalArgsItemData {
  static ProposalArgsItemData fromJson(Map<String, dynamic> json) =>
      _$ProposalArgsItemDataFromJson(json);
  Map<String, dynamic> toJson() => _$ProposalArgsItemDataToJson(this);
}

abstract class _ProposalArgsItemData {
  String? name;
  String? type;
}

@JsonSerializable()
class CouncilProposalVotesData extends _CouncilProposalVotesData {
  static CouncilProposalVotesData fromJson(Map<String, dynamic> json) =>
      _$CouncilProposalVotesDataFromJson(json);
  Map<String, dynamic> toJson() => _$CouncilProposalVotesDataToJson(this);
}

abstract class _CouncilProposalVotesData {
  int? index;
  int? threshold;
  List<String>? ayes;
  List<String>? nays;
  dynamic end;
}

@JsonSerializable()
class SpendProposalDetailData extends _SpendProposalDetailData {
  static SpendProposalDetailData fromJson(Map<String, dynamic> json) =>
      _$SpendProposalDetailDataFromJson(json);
  Map<String, dynamic> toJson() => _$SpendProposalDetailDataToJson(this);
}

abstract class _SpendProposalDetailData {
  String? proposer;
  String? beneficiary;
  dynamic value;
  dynamic bond;
}

import 'package:json_annotation/json_annotation.dart';
import 'package:polkawallet_sdk/api/types/gov/treasuryOverviewData.dart';

part 'proposalInfoData.g.dart';

@JsonSerializable()
class ProposalInfoData extends _ProposalInfoData {
  static ProposalInfoData fromJson(Map<String, dynamic> json) =>
      _$ProposalInfoDataFromJson(json);
  Map<String, dynamic> toJson() => _$ProposalInfoDataToJson(this);
}

abstract class _ProposalInfoData {
  dynamic balance;
  List<String>? seconds;
  ProposalImageData? image;
  String? imageHash;
  String? proposer;
  dynamic index;
}

@JsonSerializable()
class ProposalImageData extends _ProposalImageData {
  static ProposalImageData fromJson(Map<String, dynamic> json) =>
      _$ProposalImageDataFromJson(json);
  Map<String, dynamic> toJson() => _$ProposalImageDataToJson(this);
}

abstract class _ProposalImageData {
  dynamic balance;
  dynamic at;
  String? proposer;
  CouncilProposalData? proposal;
}

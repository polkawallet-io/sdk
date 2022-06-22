// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auctionData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuctionData _$AuctionDataFromJson(Map<String, dynamic> json) => AuctionData()
  ..auction = AuctionOverview.fromJson(json['auction'] as Map<String, dynamic>)
  ..funds = (json['funds'] as List<dynamic>)
      .map((e) => FundData.fromJson(e as Map<String, dynamic>))
      .toList()
  ..winners = (json['winners'] as List<dynamic>)
      .map((e) => BidData.fromJson(e as Map<String, dynamic>))
      .toList();

Map<String, dynamic> _$AuctionDataToJson(AuctionData instance) =>
    <String, dynamic>{
      'auction': instance.auction.toJson(),
      'funds': instance.funds.map((e) => e.toJson()).toList(),
      'winners': instance.winners.map((e) => e.toJson()).toList(),
    };

AuctionOverview _$AuctionOverviewFromJson(Map<String, dynamic> json) =>
    AuctionOverview()
      ..bestNumber = json['bestNumber'] as String?
      ..endBlock = json['endBlock'] as String?
      ..numAuctions = json['numAuctions'] as int?
      ..leasePeriod = json['leasePeriod'] as int?
      ..leaseEnd = json['leaseEnd'] as int?;

Map<String, dynamic> _$AuctionOverviewToJson(AuctionOverview instance) =>
    <String, dynamic>{
      'bestNumber': instance.bestNumber,
      'endBlock': instance.endBlock,
      'numAuctions': instance.numAuctions,
      'leasePeriod': instance.leasePeriod,
      'leaseEnd': instance.leaseEnd,
    };

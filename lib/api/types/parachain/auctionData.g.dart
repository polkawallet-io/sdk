// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auctionData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuctionData _$AuctionDataFromJson(Map<String, dynamic> json) {
  return AuctionData()
    ..auction = json['auction'] == null
        ? null
        : AuctionOverview.fromJson(json['auction'] as Map<String, dynamic>)
    ..funds =
        (json['funds'] as List)?.map((e) => FundData.fromJson(e))?.toList()
    ..winners =
        (json['winners'] as List)?.map((e) => BidData.fromJson(e))?.toList();
}

Map<String, dynamic> _$AuctionDataToJson(AuctionData instance) =>
    <String, dynamic>{
      'auction': AuctionOverview.toJson(instance.auction),
      'funds': instance.funds.map((e) => FundData.toJson(e)).toList(),
      'winners': instance.winners.map((e) => BidData.toJson(e)).toList(),
    };

AuctionOverview _$AuctionOverviewFromJson(Map<String, dynamic> json) {
  return AuctionOverview()
    ..bestNumber = json['bestNumber'] as String
    ..endBlock = json['endBlock'] as String
    ..numAuctions = json['numAuctions'] as int
    ..leasePeriod = json['leasePeriod'] as int
    ..leaseEnd = json['leaseEnd'] as int;
}

Map<String, dynamic> _$AuctionOverviewToJson(AuctionOverview instance) =>
    <String, dynamic>{
      'bestNumber': instance.bestNumber,
      'endBlock': instance.endBlock,
      'numAuctions': instance.numAuctions,
      'leasePeriod': instance.leasePeriod,
      'leaseEnd': instance.leaseEnd,
    };

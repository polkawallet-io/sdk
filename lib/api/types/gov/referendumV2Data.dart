class ReferendumData {
  ReferendumData({required this.ongoing, required this.userVotes});
  final List<ReferendumGroup> ongoing;
  final List<ReferendumVote> userVotes;
}

class ReferendumGroup {
  const ReferendumGroup(
      {required this.key, required this.trackName, required this.referenda});
  final String key;
  final String trackName;
  final List<ReferendumItem> referenda;

  static ReferendumGroup fromJson(Map<String, dynamic> json) {
    final ReferendumGroup info = ReferendumGroup(
        key: json['key'],
        trackName: json['trackName'],
        referenda: List.of(json['referenda'])
            .map((r) => ReferendumItem.fromJson(r))
            .toList());
    return info;
  }
}

class ReferendumItem {
  const ReferendumItem({
    required this.key,
    required this.trackId,
    required this.callMethod,
    required this.callDocs,
    required this.proposalHash,
    required this.submissionDeposit,
    required this.decisionDeposit,
    required this.submissionDepositAddress,
    required this.decisionDepositAddress,
    required this.confirmEnd,
    required this.decideEnd,
    required this.prepareEnd,
    required this.periodEnd,
    required this.ayes,
    required this.nays,
    required this.support,
    required this.tallyTotal,
  });
  final String key;
  final String trackId;
  final String callMethod;
  final String? callDocs;
  final String proposalHash;

  final String submissionDeposit;
  final String decisionDeposit;
  final String submissionDepositAddress;
  final String decisionDepositAddress;

  // periods
  final String? confirmEnd;
  final String? decideEnd;
  final String? prepareEnd;
  final String? periodEnd;

  // tally
  final String ayes;
  final String nays;
  final String support;
  final String tallyTotal;

  static ReferendumItem fromJson(Map<String, dynamic> json) {
    ReferendumItem info = ReferendumItem(
      key: json['key'],
      trackId: json['trackId'],
      callMethod: json['expanded']['callMethod'],
      callDocs: json['expanded']['callDocs'],
      proposalHash: json['expanded']['proposalHash'],
      submissionDeposit:
          json['expanded']['submissionDeposit']['amount'].toString(),
      submissionDepositAddress: json['expanded']['submissionDeposit']['who'],
      decisionDeposit:
          ((json['expanded']['decisionDeposit'] ?? {})['amount'] ?? 0)
              .toString(),
      decisionDepositAddress:
          (json['expanded']['decisionDeposit'] ?? {})['who'],
      confirmEnd: json['expanded']['confirmEnd'],
      decideEnd: json['expanded']['decideEnd'],
      prepareEnd: json['expanded']['prepareEnd'],
      periodEnd: json['expanded']['periodEnd'],
      ayes: json['expanded']['tally']['ayes'].toString(),
      nays: json['expanded']['tally']['nays'].toString(),
      support: json['expanded']['tally']['support'].toString(),
      tallyTotal: json['expanded']['tallyTotal'].toString(),
    );
    return info;
  }
}

class ReferendumVote {
  const ReferendumVote({
    required this.trackId,
    required this.key,
    required this.status,
    required this.endBlock,
    required this.isEnded,
    required this.isRedeemable,
    required this.vote,
  });
  final String trackId;
  final String key;
  final String status;
  final String endBlock;
  final bool isEnded;
  final bool isRedeemable;

  final Map vote;

  static ReferendumVote fromJson(Map<String, dynamic> json) {
    final ReferendumVote info = ReferendumVote(
      trackId: json['trackId'],
      key: json['key'],
      status: json['status'],
      endBlock: json['endBlock'].toString(),
      isEnded: json['isEnded'],
      isRedeemable: json['redeemable'] ?? false,
      vote: json['vote'],
    );
    return info;
  }
}

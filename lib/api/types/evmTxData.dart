import 'package:json_annotation/json_annotation.dart';

part 'evmTxData.g.dart';

@JsonSerializable()
class EvmTxData {
  final String? value;
  final String? blockHash;
  final String? blockNumber;
  final String? confirmations;
  final String? contractAddress;
  final String? cumulativeGasUsed;
  final String? from;
  final String? gas;
  final String? gasPrice;
  final String? gasUsed;
  final String? hash;
  final String? input;
  final String? logIndex;
  final String? nonce;
  final String? timeStamp;
  final String? to;
  String? tokenDecimal;
  String? tokenName;
  String? tokenSymbol;
  final String? transactionIndex;
  final String? isError;

  EvmTxData(
      {this.value,
      this.blockHash,
      this.blockNumber,
      this.confirmations,
      this.contractAddress,
      this.cumulativeGasUsed,
      this.from,
      this.gas,
      this.gasPrice,
      this.gasUsed,
      this.hash,
      this.input,
      this.logIndex,
      this.nonce,
      this.timeStamp,
      this.to,
      this.tokenDecimal,
      this.tokenName,
      this.tokenSymbol,
      this.transactionIndex,
      this.isError});

  factory EvmTxData.fromJson(Map<String, dynamic> json) =>
      _$EvmTxDataFromJson(json);

  Map<String, dynamic> toJson() => _$EvmTxDataToJson(this);
}

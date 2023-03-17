// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evmTxData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EvmTxData _$EvmTxDataFromJson(Map<String, dynamic> json) => EvmTxData(
      value: json['value'] as String?,
      blockHash: json['blockHash'] as String?,
      blockNumber: json['blockNumber'] as String?,
      confirmations: json['confirmations'] as String?,
      contractAddress: json['contractAddress'] as String?,
      cumulativeGasUsed: json['cumulativeGasUsed'] as String?,
      from: json['from'] as String?,
      gas: json['gas'] as String?,
      gasPrice: json['gasPrice'] as String?,
      gasUsed: json['gasUsed'] as String?,
      hash: json['hash'] as String?,
      input: json['input'] as String?,
      logIndex: json['logIndex'] as String?,
      nonce: json['nonce'] as String?,
      timeStamp: json['timeStamp'] as String?,
      to: json['to'] as String?,
      tokenDecimal: json['tokenDecimal'] as String?,
      tokenName: json['tokenName'] as String?,
      tokenSymbol: json['tokenSymbol'] as String?,
      transactionIndex: json['transactionIndex'] as String?,
      isError: json['isError'] as String?,
    );

Map<String, dynamic> _$EvmTxDataToJson(EvmTxData instance) => <String, dynamic>{
      'value': instance.value,
      'blockHash': instance.blockHash,
      'blockNumber': instance.blockNumber,
      'confirmations': instance.confirmations,
      'contractAddress': instance.contractAddress,
      'cumulativeGasUsed': instance.cumulativeGasUsed,
      'from': instance.from,
      'gas': instance.gas,
      'gasPrice': instance.gasPrice,
      'gasUsed': instance.gasUsed,
      'hash': instance.hash,
      'input': instance.input,
      'logIndex': instance.logIndex,
      'nonce': instance.nonce,
      'timeStamp': instance.timeStamp,
      'to': instance.to,
      'tokenDecimal': instance.tokenDecimal,
      'tokenName': instance.tokenName,
      'tokenSymbol': instance.tokenSymbol,
      'transactionIndex': instance.transactionIndex,
      'isError': instance.isError,
    };

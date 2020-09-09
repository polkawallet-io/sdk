import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk_example/pages/keyring.dart';

class TxPage extends StatefulWidget {
  TxPage(this.sdk, this.showResult);

  final WalletSDK sdk;
  final Function(BuildContext, String, String) showResult;

  static const String route = '/tx';

  @override
  _TxPageState createState() => _TxPageState();
}

class _TxPageState extends State<TxPage> {
  final String _testPubKey =
      '0xe611c2eced1b561183f88faed0dd7d88d5fafdf16f5840c63ec36d8c31136f61';
  final String _testAddress =
      '16CfHoeSifpXMtxVvNAkwgjaeBXK8rAm2CYJvQw4MKMjVHgm';
  final String _testAddressGav =
      'FcxNWVy5RESDsErjwyZmPCW6Z8Y3fbfLzmou34YZTrbcraL';

  bool _submitting = false;

  Future<void> _estimateTxFee() async {
    setState(() {
      _submitting = true;
    });
    final txInfo = TxInfoData();
    txInfo.module = 'balances';
    txInfo.call = 'transfer';
    txInfo.pubKey = _testPubKey;
    txInfo.address = _testAddress;
    final res = await widget.sdk.api.tx.estimateTxFees(txInfo, [
      // params.to
      _testAddressGav,
      // params.amount
      '10000000000'
    ]);
    widget.showResult(context, 'estimateTxFees',
        JsonEncoder.withIndent('  ').convert(TxFeeEstimateResult.toJson(res)));
    setState(() {
      _submitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('keyring API'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              title: Text('estimateTxFee'),
              subtitle: Text(
                  'sdk.api.tx.estimateTxFee(txInfo, ["$_testAddress", "10000000000"])'),
              trailing: SubmitButton(
                needConnect: !widget.sdk.api.isConnected,
                submitting: _submitting,
                call: _estimateTxFee,
              ),
            ),
            Divider(),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

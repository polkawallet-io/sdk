import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk_example/pages/keyring.dart';

class TxPage extends StatefulWidget {
  TxPage(this.sdk, this.keyring, this.showResult);

  final WalletSDK sdk;
  final Keyring keyring;
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

  final _testPass = 'a123456';

  bool _submitting = false;
  String? _status;

  Future<void> _estimateTxFee() async {
    setState(() {
      _submitting = true;
    });
    final sender = TxSenderData(_testAddress, _testPubKey);
    final txInfo = TxInfoData('balances', 'transfer', sender);
    final res = await widget.sdk.api.tx.estimateFees(txInfo, [
      // params.to
      _testAddressGav,
      // params.amount
      '10000000000'
    ]);
    widget.showResult(context, 'estimateTxFees',
        JsonEncoder.withIndent('  ').convert(res.toJson()));
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _sendTx() async {
    if (widget.keyring.keyPairs.length == 0) {
      widget.showResult(
        context,
        'sendTx',
        'should import keyPair to init test account.',
      );
      return;
    }
    setState(() {
      _submitting = true;
    });
    final sender = TxSenderData(
      widget.keyring.keyPairs[0].address,
      widget.keyring.keyPairs[0].pubKey,
    );
    final txInfo = TxInfoData('balances', 'transfer', sender);
    try {
      final hash = await widget.sdk.api.tx.signAndSend(
        txInfo,
        [
          // params.to
          // _testAddressGav,
          'GvrJix8vF8iKgsTAfuazEDrBibiM6jgG66C6sT2W56cEZr3',
          // params.amount
          '10000000000'
        ],
        _testPass,
        onStatusChange: (status) {
          print(status);
          setState(() {
            _status = status;
          });
        },
      );
      widget.showResult(context, 'sendTx', hash.toString());
    } catch (err) {
      widget.showResult(context, 'sendTx', err.toString());
    }
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
              title: Text('send tx status: $_status'),
            ),
            Divider(),
            ListTile(
              title: Text('estimateTxFee'),
              subtitle: Text(
                  'sdk.api.tx.estimateTxFee(txInfo, ["$_testAddress", "10000000000"])'),
              trailing: SubmitButton(
                needConnect: widget.sdk.api.connectedNode == null,
                submitting: _submitting,
                call: _estimateTxFee,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('sendTx'),
              subtitle: Text('sdk.api.tx.sendTx'),
              trailing: SubmitButton(
                needConnect: widget.sdk.api.connectedNode == null,
                submitting: _submitting,
                call: _sendTx,
              ),
            ),
            Divider(),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

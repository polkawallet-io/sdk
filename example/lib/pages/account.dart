import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/api/types/balanceData.dart';
import 'package:polkawallet_sdk_example/pages/keyring.dart';

class AccountPage extends StatefulWidget {
  AccountPage(this.sdk, this.showResult);

  final WalletSDK sdk;
  final Function(BuildContext, String, String) showResult;

  static const String route = '/account';

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final String _testPubKey =
      '0xe611c2eced1b561183f88faed0dd7d88d5fafdf16f5840c63ec36d8c31136f61';
  final String _testAddress =
      '16CfHoeSifpXMtxVvNAkwgjaeBXK8rAm2CYJvQw4MKMjVHgm';
  final String _testAddressGav =
      'FcxNWVy5RESDsErjwyZmPCW6Z8Y3fbfLzmou34YZTrbcraL';

  bool _submitting = false;

  BalanceData _balance;
  String _msgChannel;

  Future<void> _encodeAddress() async {
    setState(() {
      _submitting = true;
    });
    final Map res = await widget.sdk.api.account.encodeAddress([_testPubKey]);
    widget.showResult(
      context,
      'encodeAddress',
      JsonEncoder.withIndent('  ').convert(res),
    );
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _decodeAddress() async {
    setState(() {
      _submitting = true;
    });
    final Map res = await widget.sdk.api.account.decodeAddress([_testAddress]);
    widget.showResult(
      context,
      'decodeAddress',
      JsonEncoder.withIndent('  ').convert(res),
    );
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _getPubKeyIcons() async {
    setState(() {
      _submitting = true;
    });
    final List res = await widget.sdk.api.account.getPubKeyIcons([_testPubKey]);
    widget.showResult(
        context, 'getPubKeyIcons', JsonEncoder.withIndent('  ').convert(res));
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _getAddressIcons() async {
    setState(() {
      _submitting = true;
    });
    final List res =
        await widget.sdk.api.account.getAddressIcons([_testAddress]);
    widget.showResult(
        context, 'getAddressIcons', JsonEncoder.withIndent('  ').convert(res));
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _queryIndexInfo() async {
    setState(() {
      _submitting = true;
    });
    final List res = await widget.sdk.api.account
        .queryIndexInfo([_testAddress, _testAddressGav]);
    widget.showResult(
        context, 'queryIndexInfo', JsonEncoder.withIndent('  ').convert(res));
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _queryBalance() async {
    setState(() {
      _submitting = true;
    });
    final res = await widget.sdk.api.account.queryBalance(_testAddress);
    widget.showResult(context, 'queryBalance',
        JsonEncoder.withIndent('  ').convert(res.toJson()));
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _subscribeBalance() async {
    final channel =
        await widget.sdk.api.account.subscribeBalance(_testAddress, (res) {
      setState(() {
        _balance = res;
      });
    });
    setState(() {
      _msgChannel = channel;
    });
  }

  Future<void> _checkAddressFormat() async {
    setState(() {
      _submitting = true;
    });
    final res =
        await widget.sdk.api.account.checkAddressFormat(_testAddress, 2);
    widget.showResult(context, 'checkAddressFormat',
        JsonEncoder.withIndent('  ').convert(res));
    setState(() {
      _submitting = false;
    });
  }

  @override
  void dispose() {
    if (_msgChannel != null) {
      widget.sdk.api.unsubscribeMessage(_msgChannel);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('account API'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              title: Text('subscribe balance: ${_balance?.freeBalance}'),
            ),
            Divider(),
            ListTile(
              title: Text('encodeAddress'),
              subtitle: Text('sdk.api.account.encodeAddress(["$_testPubKey"])'),
              trailing: SubmitButton(
                needConnect: widget.sdk.api.connectedNode == null,
                submitting: _submitting,
                call: _encodeAddress,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('decodeAddress'),
              subtitle:
                  Text('sdk.api.account.decodeAddress(["$_testAddress"])'),
              trailing: SubmitButton(
                submitting: _submitting,
                call: _decodeAddress,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('getPubKeyIcons'),
              subtitle:
                  Text('sdk.api.account.getPubKeyIcons(["$_testPubKey"])'),
              trailing: SubmitButton(
                submitting: _submitting,
                call: _getPubKeyIcons,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('getAddressIcons'),
              subtitle:
                  Text('sdk.api.account.getAddressIcons(["$_testAddress"])'),
              trailing: SubmitButton(
                submitting: _submitting,
                call: _getAddressIcons,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('queryIndexInfo'),
              subtitle: Text(
                  'sdk.api.account.queryIndexInfo(["$_testAddress", "$_testAddressGav"])'),
              trailing: SubmitButton(
                needConnect: widget.sdk.api.connectedNode == null,
                submitting: _submitting,
                call: _queryIndexInfo,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('queryBalance'),
              subtitle: Text('sdk.api.account.queryBalance("$_testAddress")'),
              trailing: SubmitButton(
                needConnect: widget.sdk.api.connectedNode == null,
                submitting: _submitting,
                call: _queryBalance,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('subscribeBalance'),
              subtitle: Text(
                  'sdk.api.account.subscribeBalance("$_testAddress", onUpdate: (res) => {})'),
              trailing: SubmitButton(
                needConnect: widget.sdk.api.connectedNode == null,
                submitting: _submitting,
                call: _subscribeBalance,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('checkAddressFormat'),
              subtitle: Text(
                  'sdk.api.account.checkAddressFormat(["$_testPubKey"],2)'),
              trailing: SubmitButton(
                // needConnect: !widget.sdk.api.isConnected,
                submitting: _submitting,
                call: _checkAddressFormat,
              ),
            ),
            Divider(),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

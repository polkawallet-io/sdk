import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
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
      '0xa2d1d33cc490d34ccc6938f8b30430428da815a85bf5927adc85d9e27cbbfc1a';
  final String _testAddress =
      '14gV68QsGAEUGkcuV5JA1hx2ZFTuKJthMFfnkDyLMZyn8nnb';

  bool _apiConnected = false;
  bool _submitting = false;

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
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

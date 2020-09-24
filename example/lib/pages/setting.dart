import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/api/types/networkStateData.dart';
import 'package:polkawallet_sdk_example/pages/keyring.dart';

class SettingPage extends StatefulWidget {
  SettingPage(this.sdk, this.showResult);

  final WalletSDK sdk;
  final Function(BuildContext, String, String) showResult;

  static const String route = '/setting';

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool _submitting = false;

  int _bestNumber;
  String _bestNumberMsgChannel;

  Future<void> _queryNetworkConst() async {
    setState(() {
      _submitting = true;
    });
    final Map res = await widget.sdk.api.setting.queryNetworkConst();
    widget.showResult(
      context,
      'queryNetworkConst',
      JsonEncoder.withIndent('  ').convert(res),
    );
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _queryNetworkProperties() async {
    setState(() {
      _submitting = true;
    });
    final NetworkStateData res =
        await widget.sdk.api.setting.queryNetworkProps();
    widget.showResult(
      context,
      'queryNetworkProps',
      JsonEncoder.withIndent('  ').convert(res.toJson()),
    );
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _subscribeBestNumber() async {
    final msgChannel = await widget.sdk.api.setting.subscribeBestNumber((res) {
      setState(() {
        _bestNumber = res;
      });
    });
    setState(() {
      _bestNumberMsgChannel = msgChannel;
    });
  }

  Future<void> _unsubscribeBestNumber() async {
    if (_bestNumberMsgChannel != null) {
      widget.sdk.api.unsubscribeMessage(_bestNumberMsgChannel);
    }
  }

  @override
  void dispose() {
    _unsubscribeBestNumber();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('setting API'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('bestNumber: #$_bestNumber'),
            ),
            Divider(),
            ListTile(
              title: Text('queryNetworkConst'),
              subtitle: Text('sdk.api.setting.queryNetworkConst()'),
              trailing: SubmitButton(
                submitting: _submitting,
                call: _queryNetworkConst,
                needConnect: widget.sdk.api.connectedNode == null,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('queryNetworkProps'),
              subtitle: Text('sdk.api.setting.queryNetworkProps()'),
              trailing: SubmitButton(
                submitting: _submitting,
                call: _queryNetworkProperties,
                needConnect: widget.sdk.api.connectedNode == null,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('subscribeBestNumber'),
              subtitle: Text('sdk.api.setting.subscribeBestNumber()'),
              trailing: SubmitButton(
                submitting: _submitting,
                call: _subscribeBestNumber,
                needConnect: widget.sdk.api.connectedNode == null,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('unsubscribeBestNumber'),
              subtitle: Text('sdk.api.setting.unsubscribeBestNumber()'),
              trailing: SubmitButton(
                submitting: _submitting,
                call: _unsubscribeBestNumber,
                needConnect: widget.sdk.api.connectedNode == null,
              ),
            ),
            Divider(),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

import 'keyring.dart';

class StakingPage extends StatefulWidget {
  static const String route = '/staking';

  final WalletSDK sdk;
  final Keyring keyring;
  final Function(BuildContext, String, String) showResult;

  StakingPage(this.sdk, this.keyring, this.showResult);

  @override
  _StakingPageState createState() => _StakingPageState();
}

class _StakingPageState extends State<StakingPage> {
  final String _testPubKey =
      '0xe611c2eced1b561183f88faed0dd7d88d5fafdf16f5840c63ec36d8c31136f61';

  bool _submitting = false;

  Future<void> _queryElectedInfo() async {
    setState(() {
      _submitting = true;
    });
    final res = await widget.sdk.api.staking.queryElectedInfo();
    widget.showResult(
        context, 'queryElectedInfo', JsonEncoder.withIndent('  ').convert(res));
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _queryNominations() async {
    setState(() {
      _submitting = true;
    });
    final res = await widget.sdk.api.staking.queryNominations();
    widget.showResult(
        context, 'queryNominations', JsonEncoder.withIndent('  ').convert(res));
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _queryBonded() async {
    setState(() {
      _submitting = true;
    });
    final res = await widget.sdk.api.staking.queryBonded([_testPubKey]);
    widget.showResult(context, 'queryBonded',
        JsonEncoder.withIndent('  ').convert(res.toString()));
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _getAccountRewardsEraOptions() async {
    setState(() {
      _submitting = true;
    });
    final res = await widget.sdk.api.staking.getAccountRewardsEraOptions();
    widget.showResult(context, 'getAccountRewardsEraOptions',
        JsonEncoder.withIndent('  ').convert(res.toString()));
    setState(() {
      _submitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staking API'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              title: Text('queryElectedInfo'),
              subtitle: Text('sdk.api.staking.queryElectedInfo()'),
              trailing: SubmitButton(
                needConnect: widget.sdk.api.connectedNode == null,
                submitting: _submitting,
                call: _queryElectedInfo,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('queryNominations'),
              subtitle: Text('sdk.api.staking.queryNominations()'),
              trailing: SubmitButton(
                needConnect: widget.sdk.api.connectedNode == null,
                submitting: _submitting,
                call: _queryNominations,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('queryBonded'),
              subtitle: Text('sdk.api.staking.queryBonded(["$_testPubKey"])'),
              trailing: SubmitButton(
                needConnect: widget.sdk.api.connectedNode == null,
                submitting: _submitting,
                call: _queryBonded,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('getAccountRewardsEraOptions'),
              subtitle: Text('sdk.api.staking.getAccountRewardsEraOptions()'),
              trailing: SubmitButton(
                needConnect: widget.sdk.api.connectedNode == null,
                submitting: _submitting,
                call: _getAccountRewardsEraOptions,
              ),
            ),
            Divider(),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk_example/pages/keyring.dart';

class BridgePage extends StatefulWidget {
  BridgePage(this.sdk, this.showResult);

  final WalletSDK sdk;
  final Function(BuildContext, String, String) showResult;

  static const String route = '/bridge';

  @override
  _BridgePageState createState() => _BridgePageState();
}

class _BridgePageState extends State<BridgePage> {
  final String _testAddress =
      '5GREeQcGHt7na341Py6Y6Grr38KUYRvVoiFSiDB52Gt7VZiN';
  bool _submitting = false;

  Future<void> _testAllApis() async {
    setState(() {
      _submitting = true;
    });
    bool isSuccess = true;
    final chainsAll = await widget.sdk.api.bridge.getFromChainsAll();
    if (chainsAll.length < 2) {
      isSuccess = false;
    }
    final routes = await widget.sdk.api.bridge.getRoutes();
    if (routes.length < 2 || routes[0].token.length < 3) {
      isSuccess = false;
    }
    final chainsInfo = await widget.sdk.api.bridge.getChainsInfo();
    if (chainsInfo.length < 6 || chainsInfo[chainsAll[0]]!.id.length < 3) {
      isSuccess = false;
    }
    final connected = await widget.sdk.api.bridge.connectFromChains();
    if (connected.length < 2) {
      isSuccess = false;
    }
    final config = await widget.sdk.api.bridge.getAmountInputConfig(
        connected[0], connected[1], routes[0].token, _testAddress);
    if (config.from != connected[0] ||
        config.to != connected[1] ||
        config.token != routes[0].token) {
      isSuccess = false;
    }
    widget.sdk.api.bridge.subscribeBalances(connected[0], _testAddress,
        (res) async {
      final balance = res[routes[0].token];
      if (balance?.token != routes[0].token || balance?.decimals == null) {
        isSuccess = false;
      }

      final tx = await widget.sdk.api.bridge.getTxParams(
          connected[0],
          connected[1],
          routes[0].token,
          _testAddress,
          '23300000000',
          balance?.decimals ?? 8);
      if (tx.module.isEmpty || tx.call.isEmpty || tx.params.length == 0) {
        isSuccess = false;
      }
      await widget.sdk.api.bridge.disconnectFromChains();
      widget.showResult(
        context,
        'test all apis',
        isSuccess ? 'success' : 'error',
      );
      setState(() {
        _submitting = false;
      });
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
              title: Text('testAllBridgeApis'),
              subtitle: Text('''
sdk.api.bridge'''),
              trailing: SubmitButton(
                submitting: _submitting,
                call: _testAllApis,
              ),
            ),
            Divider(),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

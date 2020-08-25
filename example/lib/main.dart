import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk_example/pages/account.dart';
import 'package:polkawallet_sdk_example/pages/keyring.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final WalletSDK sdk = WalletSDK();

  bool _sdkReady = false;

  Future<void> _initApi() async {
    await sdk.init();
    setState(() {
      _sdkReady = true;
    });
  }

  void _showResult(BuildContext context, String title, res) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: SelectableText(res, textAlign: TextAlign.left),
          actions: [
            CupertinoButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _initApi();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polkawallet SDK Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(sdk, _sdkReady),
      routes: {
        KeyringPage.route: (_) => KeyringPage(sdk, _showResult),
        AccountPage.route: (_) => AccountPage(sdk, _showResult),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage(this.sdk, this.sdkReady);

  final WalletSDK sdk;
  final bool sdkReady;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _apiConnected = false;

  @override
  Widget build(BuildContext context) {
    final Widget trailing = widget.sdkReady
        ? IconButton(
            icon: Icon(Icons.arrow_forward_ios, size: 18),
          )
        : CupertinoActivityIndicator();
    return Scaffold(
      appBar: AppBar(
        title: Text('Polkawallet SDK Demo'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('js-api loaded: ${widget.sdkReady}'),
                  Text('js-api connected: $_apiConnected')
                ],
              ),
            ),
            Divider(),
            ListTile(
              title: Text('sdk.keyring'),
              subtitle: Text('keyPairs management'),
              trailing: trailing,
              onTap: () {
                if (!widget.sdkReady) return;
                Navigator.of(context).pushNamed(KeyringPage.route);
              },
            ),
            Divider(),
            ListTile(
              title: Text('sdk.account'),
              subtitle: Text('account management'),
              trailing: trailing,
              onTap: () {
                if (!widget.sdkReady) return;
                Navigator.of(context).pushNamed(AccountPage.route);
              },
            )
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

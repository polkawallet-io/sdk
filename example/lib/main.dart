import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/api/types/accountData.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polkawallet SDK Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Polkawallet SDK Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final WalletSDK sdk = WalletSDK();

  bool _apiLoaded = false;
  bool _apiConnected = false;
  bool _submitting = true;

  Future<void> _initApi() async {
    await sdk.init();
    setState(() {
      _apiLoaded = true;
      _submitting = false;
    });
  }

  Future<void> _generateMnemonic() async {
    setState(() {
      _submitting = true;
    });
    final String seed = await sdk.api.keyring.generateMnemonic();
    _showResult('generateMnemonic', seed);
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _importFromMnemonic() async {
    setState(() {
      _submitting = true;
    });
    final AccountData acc = await sdk.api.keyring.importAccount(
      keyType: KeyType.mnemonic,
      key:
          'wing know chapter eight shed lens mandate lake twenty useless bless glory',
      name: 'testName01',
      password: 'a123456',
    );
    _showResult(
      'importFromMnemonic',
      JsonEncoder.withIndent('  ').convert(AccountData.toJson(acc)),
    );
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _importFromRawSeed() async {
    setState(() {
      _submitting = true;
    });
    final AccountData acc = await sdk.api.keyring.importAccount(
      keyType: KeyType.mnemonic,
      key: 'Alice',
      name: 'testName02',
      password: 'a123456',
    );
    _showResult(
      'importFromRawSeed',
      JsonEncoder.withIndent('  ').convert(AccountData.toJson(acc)),
    );
    setState(() {
      _submitting = false;
    });
  }

  void _showResult(String title, res) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('js-api loaded: $_apiLoaded'),
                  Text('js-api connected: $_apiConnected')
                ],
              ),
            ),
            Divider(),
            ListTile(
              title: Text('generateMnemonic'),
              subtitle: Text('sdk.api.account.generateMnemonic()'),
              trailing: IconButton(
                color: _submitting
                    ? Theme.of(context).disabledColor
                    : Theme.of(context).primaryColor,
                icon: _submitting
                    ? Icon(Icons.refresh)
                    : Icon(Icons.play_circle_outline),
                onPressed: () => _generateMnemonic(),
              ),
            ),
            Divider(),
            ListTile(
              title: Text('importFromMnemonic'),
              subtitle: Text('''
sdk.api.account.importAccount(
    keyType: KeyType.mnemonic,
    key: 'wing know chapter eight shed lens mandate lake twenty useless bless glory',
    name: 'testName01',
    password: 'a123456',
)'''),
              trailing: IconButton(
                color: _submitting
                    ? Theme.of(context).disabledColor
                    : Theme.of(context).primaryColor,
                icon: _submitting
                    ? Icon(Icons.refresh)
                    : Icon(Icons.play_circle_outline),
                onPressed: () => _importFromMnemonic(),
              ),
            ),
            Divider(),
            ListTile(
              title: Text('importFromRawSeed'),
              subtitle: Text('''
sdk.api.account.importAccount(
    keyType: KeyType.rawSeed,
    key: 'Alice',
    name: 'testName02',
    password: 'a123456',
)'''),
              trailing: IconButton(
                color: _submitting
                    ? Theme.of(context).disabledColor
                    : Theme.of(context).primaryColor,
                icon: _submitting
                    ? Icon(Icons.refresh)
                    : Icon(Icons.play_circle_outline),
                onPressed: () => _importFromRawSeed(),
              ),
            ),
            Divider(),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

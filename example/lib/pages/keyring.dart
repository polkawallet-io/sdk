import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/api/types/accountData.dart';

class KeyringPage extends StatefulWidget {
  KeyringPage(this.sdk, this.showResult);

  final WalletSDK sdk;
  final Function(BuildContext, String, String) showResult;

  static const String route = '/keyring';

  @override
  _KeyringPageState createState() => _KeyringPageState();
}

class _KeyringPageState extends State<KeyringPage> {
  final String _testJson = '''{
      "pubKey":"0xa2d1d33cc490d34ccc6938f8b30430428da815a85bf5927adc85d9e27cbbfc1a",
      "address":"14gV68QsGAEUGkcuV5JA1hx2ZFTuKJthMFfnkDyLMZyn8nnb",
      "encoded":"G3BHvs9tVTSf1Qe02bcOGpj7vjLdgqyS+/s0/J3EfRMAgAAAAQAAAAgAAADpWTEOs5/06DmEZaeuoExpf9+y1xcUhIzmEr6dUxyl67VQRX2KNGVmTqq05/sEIUDPVeOqqLbjBEPaNRoC0lZTQlKM5u38lX4PzKivGHM9ZJkvtQxf7RAndN/vgfIX4X76gX60bqrUY8Qr2ZswtuPTeGVKQOD7y0GtoPOcR2RzFg6rs44NuugTR0UwA8HWTDkh0c/KOnUc1FJDb4rV",
      "encoding":{"content":["pkcs8","sr25519"],"type":["scrypt","xsalsa20-poly1305"],"version":"3"},
      "meta": {
        "name": "testName-3",
        "whenCreated": 1598270113026,
        "whenEdited": 1598270113026
      }}''';

  bool _apiConnected = false;
  bool _submitting = false;

  Future<void> _generateMnemonic() async {
    setState(() {
      _submitting = true;
    });
    final String seed = await widget.sdk.api.keyring.generateMnemonic();
    widget.showResult(context, 'generateMnemonic', seed);
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _importFromMnemonic() async {
    setState(() {
      _submitting = true;
    });
    final AccountData acc = await widget.sdk.api.keyring.importAccount(
      keyType: KeyType.mnemonic,
      key:
          'wing know chapter eight shed lens mandate lake twenty useless bless glory',
      name: 'testName01',
      password: 'a123456',
    );
    widget.showResult(
      context,
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
    final AccountData acc = await widget.sdk.api.keyring.importAccount(
      keyType: KeyType.mnemonic,
      key: 'Alice',
      name: 'testName02',
      password: 'a123456',
    );
    widget.showResult(
      context,
      'importFromRawSeed',
      JsonEncoder.withIndent('  ').convert(AccountData.toJson(acc)),
    );
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _importFromKeystore() async {
    setState(() {
      _submitting = true;
    });
    final AccountData acc = await widget.sdk.api.keyring.importAccount(
      keyType: KeyType.keystore,
      key: _testJson,
      name: 'testName03',
      password: 'a123456',
    );
    widget.showResult(
      context,
      'importFromKeystore',
      JsonEncoder.withIndent('  ').convert(AccountData.toJson(acc)),
    );
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
            ListTile(
              title: Text('importFromKeystore'),
              subtitle: Text('''
sdk.api.account.importAccount(
    keyType: KeyType.keystore,
    key: '{xxx...xxx}',
    name: 'testName03',
    password: 'a123456',
)'''),
              trailing: IconButton(
                color: _submitting
                    ? Theme.of(context).disabledColor
                    : Theme.of(context).primaryColor,
                icon: _submitting
                    ? Icon(Icons.refresh)
                    : Icon(Icons.play_circle_outline),
                onPressed: () => _importFromKeystore(),
              ),
            ),
            Divider(),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

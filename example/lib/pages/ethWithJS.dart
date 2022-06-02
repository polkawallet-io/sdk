import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/types/addressIconData.dart';
import 'package:polkawallet_sdk/ethers/apiEthers.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/storage/keyringEVM.dart';
import 'package:polkawallet_sdk/storage/types/ethWalletData.dart';
import 'package:polkawallet_sdk_example/pages/keyring.dart';

class EthWithJSPage extends StatefulWidget {
  EthWithJSPage(this.sdk, this.keyring, this.showResult);

  final WalletSDK sdk;
  final KeyringEVM keyring;
  final Function(BuildContext, String, String) showResult;

  static const String route = '/keyring/eth/js';

  @override
  _EthWithJSPageState createState() => _EthWithJSPageState();
}

class _EthWithJSPageState extends State<EthWithJSPage> {
  final String _testJson = '''{
  "crypto": {"cipher": "aes-128-ctr", "cipherparams": {"iv": "3be45c336ce8cd771061e3b5ec9460ec"}, "ciphertext": "b4e181f629e480d4073edfe6f0ad7bc8c201ac3975eb0232150e4550f59af1c0", "kdf": "scrypt", "kdfparams": {"dklen": 32, "n": 8192, "r": 8, "p": 1, "salt": "4771ff99bf695bab6d292330678a800f8acb1831134678df45b6911fab94f38c"}, "mac": "ed5cec3eed91ab251650657cff87c693a2672413658ff7da4c2f38598f21984a"},
  "id": "3228f3c9-dfee-4e65-9569-5c8a7afc3921",
  "version": 3,
  "address": "0x4b248f45dfbea07de1bbd69180f6695b78250caf"
  }''';
  final String _testPass = 'a123456';

  EthWalletData _testAcc;

  bool _submitting = false;

  Future<void> _generateMnemonic() async {
    setState(() {
      _submitting = true;
    });
    final AddressIconDataWithMnemonic seed =
        await widget.sdk.api.eth.keyring.generateMnemonic();
    widget.showResult(context, 'generateMnemonic', seed.mnemonic);
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _getAccountList() async {
    final List<EthWalletData> ls = widget.keyring.keyPairs;
    widget.showResult(
      context,
      'getAccountList',
      JsonEncoder.withIndent('  ')
          .convert(ls.map((e) => '${e.name}: ${e.address}').toList()),
    );
  }

  Future<void> _getDecryptedSeed() async {
    if (_testAcc == null) {
      widget.showResult(
        context,
        'getDecryptedSeeds',
        'should import keyPair to init test account.',
      );
      return;
    }
    setState(() {
      _submitting = true;
    });
    final seed = await widget.sdk.api.eth.keyring
        .getDecryptedSeed(widget.keyring, _testPass);
//        await widget.sdk.evm.getDecryptedSeed(widget.keyring, 'a654321');
    widget.showResult(
      context,
      'getDecryptedSeeds',
      seed == null
          ? 'null'
          : JsonEncoder.withIndent('  ').convert({
              'address': _testAcc.address,
              'type': seed.type,
              'seed': seed.seed,
              'error': seed.error,
            }),
    );
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _importFromMnemonic() async {
    setState(() {
      _submitting = true;
    });
    final json = await widget.sdk.api.eth.keyring.importAccount(
      keyType: EVMKeyType.mnemonic,
      key:
          'wing know chapter eight shed lens mandate lake twenty useless bless glory',
      name: 'testName01',
      password: _testPass,
    );
    print(json);
    final acc = await widget.sdk.api.eth.keyring.addAccount(
      widget.keyring,
      keyType: EVMKeyType.mnemonic,
      acc: json,
      password: _testPass,
    );
    widget.showResult(
      context,
      'importFromMnemonic',
      JsonEncoder.withIndent('  ').convert(acc.toJson()),
    );
    setState(() {
      _submitting = false;
      _testAcc = acc;
    });
  }

  Future<void> _importFromPrivateKey() async {
    setState(() {
      _submitting = true;
    });
    final json = await widget.sdk.api.eth.keyring.importAccount(
      keyType: EVMKeyType.privateKey,
      key: '0x2defc5ff7c700eb3a39a702e9b38534e8ea3419b93b1836dc6ccc891ce359290',
      name: 'testName02',
      password: _testPass,
    );
    print(json);
    final acc = await widget.sdk.api.eth.keyring.addAccount(
      widget.keyring,
      keyType: EVMKeyType.privateKey,
      acc: json,
      password: _testPass,
    );
    widget.showResult(
      context,
      'importFromPrivateKey',
      JsonEncoder.withIndent('  ').convert(acc.toJson()),
    );
    setState(() {
      _submitting = false;
      _testAcc = acc;
    });
  }

  Future<void> _importFromKeystore() async {
    setState(() {
      _submitting = true;
    });
    final json = await widget.sdk.api.eth.keyring.importAccount(
      keyType: EVMKeyType.keystore,
      key: _testJson,
      name: 'testName03',
      password: _testPass,
    );
    final acc = await widget.sdk.api.eth.keyring.addAccount(
      widget.keyring,
      keyType: EVMKeyType.keystore,
      acc: json,
      password: _testPass,
    );
    widget.showResult(
      context,
      'importFromKeystore',
      JsonEncoder.withIndent('  ').convert(acc.toJson()),
    );
    setState(() {
      _submitting = false;
      _testAcc = acc;
    });
  }

  Future<void> _deleteAccount() async {
    if (_testAcc == null) {
      widget.showResult(
        context,
        'deleteAccount',
        'should import keyPair to init test account.',
      );
      return;
    }
    setState(() {
      _submitting = true;
    });
    await widget.sdk.api.eth.keyring.deleteAccount(widget.keyring, _testAcc);
    widget.showResult(
      context,
      'deleteAccount',
      'ok',
    );
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _checkPassword() async {
    if (_testAcc == null) {
      widget.showResult(
        context,
        'checkPassword',
        'should import keyPair to init test account.',
      );
      return;
    }
    setState(() {
      _submitting = true;
    });
    final bool passed =
        await widget.sdk.api.eth.keyring.checkPassword(_testAcc, _testPass);
    // await widget.sdk.evm.checkPassword(_testAcc, 'a654321');
    widget.showResult(
      context,
      'checkPassword',
      passed.toString(),
    );
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _changePassword() async {
    if (_testAcc == null) {
      widget.showResult(
        context,
        'changePassword',
        'should import keyPair to init test account.',
      );
      return;
    }
    setState(() {
      _submitting = true;
    });
    final res = await widget.sdk.api.eth.keyring
        .changePassword(widget.keyring, _testPass, 'a654321');
    // .changePassword(widget.keyring, 'a654321', _testPass);
    widget.showResult(
      context,
      'changePassword',
      res == null ? 'null' : JsonEncoder.withIndent('  ').convert(res.toJson()),
    );
    setState(() {
      _submitting = false;
      _testAcc = res;
    });
  }

  Future<void> _changeName() async {
    if (_testAcc == null) {
      widget.showResult(
        context,
        'changeName',
        'should import keyPair to init test account.',
      );
      return;
    }
    setState(() {
      _submitting = true;
    });
    final res =
        await widget.sdk.api.eth.keyring.changeName(widget.keyring, 'newName');
    widget.showResult(
      context,
      'changeName',
      res == null ? 'null' : JsonEncoder.withIndent('  ').convert(res.toJson()),
    );
    setState(() {
      _submitting = false;
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.keyring.keyPairs.length > 0) {
        setState(() {
          _testAcc = widget.keyring.keyPairs[0];
        });
      }
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
//             Padding(
//               padding: EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('address ss58Format: ${widget.keyring.ss58}'),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       RaisedButton(
//                         child: Text('Polkadot: 0'),
//                         color:
//                             _ss58 == 0 ? Theme.of(context).primaryColor : null,
//                         onPressed: () => _setSS58(0),
//                       ),
//                       RaisedButton(
//                         child: Text('Kusama: 2'),
//                         color:
//                             _ss58 == 2 ? Theme.of(context).primaryColor : null,
//                         onPressed: () => _setSS58(2),
//                       ),
//                       RaisedButton(
//                         child: Text('Substrate: 42'),
//                         color:
//                             _ss58 == 42 ? Theme.of(context).primaryColor : null,
//                         onPressed: () => _setSS58(42),
//                       )
//                     ],
//                   )
//                 ],
//               ),
//             ),
//             Divider(),
            ListTile(
              title: Text('getAccountList'),
              subtitle: Text('''
sdk.api.keyring.accountList'''),
              trailing: SubmitButton(
                submitting: _submitting,
                call: _getAccountList,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('generateMnemonic'),
              subtitle: Text('sdk.api.keyring.generateMnemonic()'),
              trailing: SubmitButton(
                submitting: _submitting,
                call: _generateMnemonic,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('importFromMnemonic'),
              subtitle: Text('''
sdk.api.keyring.importAccount(
    keyType: KeyType.mnemonic,
    key: 'wing know chapter eight shed lens mandate lake twenty useless bless glory',
    name: 'testName01',
    password: 'a123456',
)'''),
              trailing: SubmitButton(
                submitting: _submitting,
                call: _importFromMnemonic,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('importFromPrivateKey'),
              subtitle: Text('''
sdk.api.keyring.importAccount(
    keyType: KeyType.privateKey,
    key: 'Alice',
    name: 'testName02',
    password: 'a123456',
)'''),
              trailing: SubmitButton(
                submitting: _submitting,
                call: _importFromPrivateKey,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('importFromKeystore'),
              subtitle: Text('''
sdk.api.keyring.importAccount(
    keyType: KeyType.keystore,
    key: '{xxx...xxx}',
    name: 'testName03',
    password: 'a123456',
)'''),
              trailing: SubmitButton(
                submitting: _submitting,
                call: _importFromKeystore,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('getDecryptedSeed'),
              subtitle: Text('''
sdk.api.keyring.getDecryptedSeed(
    '${_testAcc?.toString()}',
    'a123456',
)'''),
              trailing: SubmitButton(
                submitting: _submitting,
                call: _getDecryptedSeed,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('deleteAccount'),
              subtitle: Text('''
sdk.api.keyring.deleteAccount'''),
              trailing: SubmitButton(
                submitting: _submitting,
                call: _deleteAccount,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('checkPassword'),
              subtitle: Text('''
sdk.api.keyring.checkPassword(
    '${_testAcc?.toString()}',
    'a123456',
)'''),
              trailing: SubmitButton(
                submitting: _submitting,
                call: _checkPassword,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('changePassword'),
              subtitle: Text('''
sdk.api.keyring.changePassword(
    '${_testAcc?.toString()}',
    'a123456',
    'a654321',
)'''),
              trailing: SubmitButton(
                submitting: _submitting,
                call: _changePassword,
              ),
            ),
            Divider(),
            ListTile(
              title: Text('changeName'),
              subtitle: Text('''
sdk.api.keyring.changeName(
    '${_testAcc?.toString()}',
    'newName',
)'''),
              trailing: SubmitButton(
                submitting: _submitting,
                call: _changeName,
              ),
            ),
            Divider(),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

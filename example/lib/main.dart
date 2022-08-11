import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/keyringEVM.dart';
import 'package:polkawallet_sdk_example/pages/account.dart';
import 'package:polkawallet_sdk_example/pages/dAppPage.dart';
import 'package:polkawallet_sdk_example/pages/ethWithJS.dart';
import 'package:polkawallet_sdk_example/pages/evm.dart';
import 'package:polkawallet_sdk_example/pages/keyring.dart';
import 'package:polkawallet_sdk_example/pages/setting.dart';
import 'package:polkawallet_sdk_example/pages/tx.dart';

import 'pages/staking.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final WalletSDK sdk = WalletSDK();
  final Keyring keyring = Keyring();
  final KeyringEVM keyringEVM = KeyringEVM();

  bool _sdkReady = false;

  Future<void> _initApi() async {
    await keyring.init([0, 2]);
    await keyringEVM.init();

    await sdk.init(keyring, keyringEVM);
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
      home: MyHomePage(sdk, keyring, _sdkReady),
      routes: {
        DAppPage.route: (_) => DAppPage(sdk, keyring),
        KeyringPage.route: (_) => KeyringPage(sdk, keyring, _showResult),
        SettingPage.route: (_) => SettingPage(sdk, _showResult),
        AccountPage.route: (_) => AccountPage(sdk, _showResult),
        TxPage.route: (_) => TxPage(sdk, keyring, _showResult),
        StakingPage.route: (_) => StakingPage(sdk, keyring, _showResult),
        EVMPage.route: (_) => EVMPage(sdk, keyringEVM, _showResult),
        EthWithJSPage.route: (_) => EthWithJSPage(sdk, keyringEVM, _showResult),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage(this.sdk, this.keyring, this.sdkReady);

  final WalletSDK sdk;
  final Keyring keyring;
  final bool sdkReady;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _connecting = false;
  bool _apiConnected = false;

  Future<void> _connectNode() async {
    setState(() {
      _connecting = true;
    });
    final node = NetworkParams();
    node.name = 'Kusama';
    node.endpoint = 'wss://kusama.api.onfinality.io/public-ws/';
    node.ss58 = 2;
    final res = await widget.sdk.api.connectNode(widget.keyring, [node]);
    if (res != null) {
      setState(() {
        _apiConnected = true;
      });
    }
    setState(() {
      _connecting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget trailing = widget.sdkReady
        ? IconButton(
            icon: Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: null,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('js-api connected: $_apiConnected'),
                      OutlinedButton(
                        child: _connecting
                            ? CupertinoActivityIndicator()
                            : Text(_apiConnected
                                ? 'connected ${widget.sdk.api.connectedNode?.name}'
                                : 'connect'),
                        onPressed: _apiConnected || _connecting
                            ? null
                            : () => _connectNode(),
                      )
                    ],
                  ),
                ],
              ),
            ),
            Divider(),
            ListTile(
              title: Text('WebViewWithExtension'),
              subtitle: Text('open polkassembly.io (DApp)'),
              trailing: trailing,
              onTap: () {
                if (!widget.sdkReady) return;
                Navigator.of(context).pushNamed(DAppPage.route,
                    arguments: "https://apps.acala.network/#/loan");
              },
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
              title: Text('sdk.setting'),
              subtitle: Text('network settings'),
              trailing: trailing,
              onTap: () {
                if (!widget.sdkReady) return;
                Navigator.of(context).pushNamed(SettingPage.route);
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
            ),
            Divider(),
            ListTile(
              title: Text('sdk.tx'),
              subtitle: Text('extrinsic actions'),
              trailing: trailing,
              onTap: () {
                if (!widget.sdkReady) return;
                Navigator.of(context).pushNamed(TxPage.route);
              },
            ),
            Divider(),
            ListTile(
              title: Text('sdk.staking'),
              subtitle: Text('staking management'),
              trailing: trailing,
              onTap: () {
                if (!widget.sdkReady) return;
                Navigator.of(context).pushNamed(StakingPage.route);
              },
            ),
            Divider(),
            ListTile(
              title: Text('ethers'),
              subtitle: Text('ethers keyring'),
              onTap: () {
                Navigator.of(context).pushNamed(EVMPage.route);
              },
            ),
            Divider(),
            ListTile(
              title: Text('sdk.eth'),
              subtitle: Text('eth js keyring'),
              onTap: () {
                Navigator.of(context).pushNamed(EthWithJSPage.route);
              },
            ),
            Divider(),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

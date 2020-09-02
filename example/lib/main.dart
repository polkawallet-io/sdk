import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk_example/pages/account.dart';
import 'package:polkawallet_sdk_example/pages/dAppPage.dart';
import 'package:polkawallet_sdk_example/pages/keyring.dart';
import 'package:polkawallet_sdk_example/pages/setting.dart';

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
        DAppPage.route: (_) => DAppPage(sdk),
        KeyringPage.route: (_) => KeyringPage(sdk, _showResult),
        SettingPage.route: (_) => SettingPage(sdk, _showResult),
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
  bool _connecting = false;
  bool _apiConnected = false;

  Future<void> _connectNode() async {
    setState(() {
      _connecting = true;
    });
    final node = NetworkParams();
    node.name = 'Kusama';
    node.endpoint = 'wss://kusama-rpc.polkadot.io/';
    node.ss58 = 2;
    final res = await widget.sdk.api.connectNode(node);
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
                      OutlineButton(
                        child: _connecting
                            ? CupertinoActivityIndicator()
                            : Text(_apiConnected
                                ? 'connected ${widget.sdk.api.connectedNode.name}'
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
            )
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

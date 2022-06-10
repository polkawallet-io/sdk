import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/webviewWithExtension/webviewWithExtension.dart';

class DAppPage extends StatefulWidget {
  DAppPage(this.sdk, this.keyring);

  static const String route = '/extension/app';

  final WalletSDK sdk;
  final Keyring keyring;

  @override
  _DAppPageState createState() => _DAppPageState();
}

class _DAppPageState extends State<DAppPage> {
  bool _loading = true;

  @override
  Widget build(BuildContext context) {
    final url = ModalRoute.of(context)?.settings.arguments as String;
    return Scaffold(
      appBar: AppBar(
          title: Text(
            url,
            style: TextStyle(fontSize: 16),
          ),
          centerTitle: true),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWithExtension(
              widget.sdk.api,
              url,
              widget.keyring,
              onPageFinished: (url) {
                setState(() {
                  _loading = false;
                });
              },
              onSignBytesRequest: (req) async {
                print(req);
                return null;
              },
              onSignExtrinsicRequest: (req) async {
                print(req);
                return null;
              },
              onConnectRequest: (req) async {
                print(req);
                return true;
              },
            ),
            _loading ? Center(child: CupertinoActivityIndicator()) : Container()
          ],
        ),
      ),
    );
  }
}

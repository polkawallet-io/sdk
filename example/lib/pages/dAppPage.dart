import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';
import 'package:polkawallet_sdk/webviewWithExtension/webviewWithExtension.dart';

class DAppPage extends StatefulWidget {
  DAppPage(this.sdk);

  static const String route = '/extension/app';

  final WalletSDK sdk;

  @override
  _DAppPageState createState() => _DAppPageState();
}

class _DAppPageState extends State<DAppPage> {
  bool _loading = true;

  @override
  Widget build(BuildContext context) {
    final String url = ModalRoute.of(context).settings.arguments;
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
              onPageFinished: (url) {
                setState(() {
                  _loading = false;
                });
              },
              onSignBytesRequest: (req) {
                print(req);
                return null;
              },
              onSignExtrinsicRequest: (req) {
                print(req);
                return null;
              },
            ),
            _loading ? Center(child: CupertinoActivityIndicator()) : Container()
          ],
        ),
      ),
    );
  }
}

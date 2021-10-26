import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewWithExtension extends StatefulWidget {
  WebViewWithExtension(
    this.api,
    this.initialUrl,
    this.keyring, {
    this.onPageFinished,
    this.onExtensionReady,
    this.onSignBytesRequest,
    this.onSignExtrinsicRequest,
  });

  final String initialUrl;
  final PolkawalletApi api;
  final Keyring keyring;
  final Function(String)? onPageFinished;
  final Function? onExtensionReady;
  final Future<ExtensionSignResult?> Function(SignAsExtensionParam)?
      onSignBytesRequest;
  final Future<ExtensionSignResult?> Function(SignAsExtensionParam)?
      onSignExtrinsicRequest;

  @override
  _WebViewWithExtensionState createState() => _WebViewWithExtensionState();
}

class _WebViewWithExtensionState extends State<WebViewWithExtension> {
  late WebViewController _controller;
  bool _loadingFinished = false;
  bool _signing = false;

  Future<String> _msgHandler(Map msg) async {
    switch (msg['msgType']) {
      case 'pub(accounts.list)':
        final List<KeyPairData> ls = widget.keyring.keyPairs;
        ls.forEach((element) {
          print(element.encoding);
        });
        ls.retainWhere((e) => e.encoding!['content'][1] == 'sr25519');
        final List res = ls.map((e) {
          return {
            'address': e.address,
            'name': e.name,
            'genesisHash': '',
          };
        }).toList();
        return _controller.evaluateJavascript(
            'walletExtension.onAppResponse("${msg['msgType']}", ${jsonEncode(res)})');
      case 'pub(bytes.sign)':
        if (_signing) break;
        _signing = true;
        final SignAsExtensionParam param =
            SignAsExtensionParam.fromJson(msg as Map<String, dynamic>);
        final res = await widget.onSignBytesRequest!(param);
        _signing = false;
        if (res == null || res.signature == null) {
          // cancelled
          return _controller.evaluateJavascript(
              'walletExtension.onAppResponse("${param.msgType}", null, new Error("Rejected"))');
        }
        return _controller.evaluateJavascript(
            'walletExtension.onAppResponse("${param.msgType}", ${jsonEncode(res.toJson())})');
      case 'pub(extrinsic.sign)':
        if (_signing) break;
        _signing = true;
        final SignAsExtensionParam params =
            SignAsExtensionParam.fromJson(msg as Map<String, dynamic>);
        final result = await widget.onSignExtrinsicRequest!(params);
        _signing = false;
        if (result == null || result.signature == null) {
          // cancelled
          return _controller.evaluateJavascript(
              'walletExtension.onAppResponse("${params.msgType}", null, new Error("Rejected"))');
        }
        return _controller.evaluateJavascript(
            'walletExtension.onAppResponse("${params.msgType}", ${jsonEncode(result.toJson())})');
      default:
        print('Unknown message from dapp: ${msg['msgType']}');
        return Future(() => "");
    }
    return Future(() => "");
  }

  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: widget.initialUrl,
      javascriptMode: JavascriptMode.unrestricted,
      onWebViewCreated: (WebViewController webViewController) {
        setState(() {
          _controller = webViewController;
        });
      },
      javascriptChannels: <JavascriptChannel>[
        JavascriptChannel(
          name: 'Extension',
          onMessageReceived: (JavascriptMessage message) {
            print('msg from dapp: ${message.message}');
            compute(jsonDecode, message.message).then((msg) {
              if (msg['path'] != 'extensionRequest') return;
              _msgHandler(msg['data']);
            });
          },
        ),
      ].toSet(),
      onPageFinished: (String url) async {
        if (_loadingFinished) return;
        setState(() {
          _loadingFinished = true;
        });

        if (widget.onPageFinished != null) {
          widget.onPageFinished!(url);
        }
        print('Page finished loading: $url');

        print('Inject extension js code...');
        final jsCode = await rootBundle.loadString(
            'packages/polkawallet_sdk/js_as_extension/dist/main.js');
        _controller.evaluateJavascript(jsCode);
        print('js code injected');
        if (widget.onExtensionReady != null) {
          widget.onExtensionReady!();
        }
      },
      gestureNavigationEnabled: true,
    );
  }
}

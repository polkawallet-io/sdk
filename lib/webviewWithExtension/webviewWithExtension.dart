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
  final Function(String) onPageFinished;
  final Function onExtensionReady;
  final Future<ExtensionSignResult> Function(SignBytesParam) onSignBytesRequest;
  final Future<ExtensionSignResult> Function(SignExtrinsicParam)
      onSignExtrinsicRequest;

  @override
  _WebViewWithExtensionState createState() => _WebViewWithExtensionState();
}

class _WebViewWithExtensionState extends State<WebViewWithExtension> {
  WebViewController _controller;
  bool _jsInjected = false;

  Future<void> _msgHandler(Map msg) async {
    switch (msg['msgType']) {
      case 'pub(accounts.list)':
        final List<KeyPairData> ls = widget.keyring.keyPairs;
        ls.retainWhere((e) => e.encoding['content'][1] == 'sr25519');
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
        final SignBytesParam param = SignBytesParam.fromJson(msg);
        final ExtensionSignResult res = await widget.onSignBytesRequest(param);
        if (res == null || res.signature == null) {
          // cancelled
          return _controller.evaluateJavascript(
              'walletExtension.onAppResponse("${param.msgType}", null, new Error("Rejected"))');
        }
        return _controller.evaluateJavascript(
            'walletExtension.onAppResponse("${param.msgType}", ${jsonEncode(ExtensionSignResult.toJson(res))})');
      case 'pub(extrinsic.sign)':
        final SignExtrinsicParam params = SignExtrinsicParam.fromJson(msg);
        final ExtensionSignResult result =
            await widget.onSignExtrinsicRequest(params);
        if (result == null || result.signature == null) {
          // cancelled
          return _controller.evaluateJavascript(
              'walletExtension.onAppResponse("${params.msgType}", null, new Error("Rejected"))');
        }
        return _controller.evaluateJavascript(
            'walletExtension.onAppResponse("${params.msgType}", ${jsonEncode(ExtensionSignResult.toJson(result))})');
      default:
        print('Unknown message from dapp: ${msg['msgType']}');
    }
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
      // TODO(iskakaushik): Remove this when collection literals makes it to stable.
      // ignore: prefer_collection_literals
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
      onPageFinished: (String url) {
        if (widget.onPageFinished != null) {
          widget.onPageFinished(url);
        }
        print('Page finished loading: $url');
        print('Inject extension js code...');
        rootBundle
            .loadString('packages/polkawallet_sdk/js_as_extension/dist/main.js')
            .then((String js) {
          if (_jsInjected) return;
          setState(() {
            _jsInjected = true;
          });

          _controller.evaluateJavascript(js);
          print('js code injected');
          if (widget.onExtensionReady != null) {
            widget.onExtensionReady();
          }
        });
      },
      gestureNavigationEnabled: true,
    );
  }
}

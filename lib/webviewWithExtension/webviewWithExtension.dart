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
  final Future<ExtensionSignResult> Function(SignAsExtensionParam)
      onSignBytesRequest;
  final Future<ExtensionSignResult> Function(SignAsExtensionParam)
      onSignExtrinsicRequest;

  @override
  _WebViewWithExtensionState createState() => _WebViewWithExtensionState();
}

class _WebViewWithExtensionState extends State<WebViewWithExtension> {
  WebViewController _controller;
  String _jsCode;
  bool _jsInjected = false;

  Future<void> _msgHandler(Map msg) async {
    switch (msg['msgType']) {
      case 'pub(accounts.list)':
        final List<KeyPairData> ls = widget.keyring.keyPairs;
        ls.forEach((element) {
          print(element.encoding);
        });
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
        final SignAsExtensionParam param = SignAsExtensionParam.fromJson(msg);
        final ExtensionSignResult res = await widget.onSignBytesRequest(param);
        if (res == null || res.signature == null) {
          // cancelled
          return _controller.evaluateJavascript(
              'walletExtension.onAppResponse("${param.msgType}", null, new Error("Rejected"))');
        }
        return _controller.evaluateJavascript(
            'walletExtension.onAppResponse("${param.msgType}", ${jsonEncode(res.toJson())})');
      case 'pub(extrinsic.sign)':
        final SignAsExtensionParam params = SignAsExtensionParam.fromJson(msg);
        final ExtensionSignResult result =
            await widget.onSignExtrinsicRequest(params);
        if (result == null || result.signature == null) {
          // cancelled
          return _controller.evaluateJavascript(
              'walletExtension.onAppResponse("${params.msgType}", null, new Error("Rejected"))');
        }
        return _controller.evaluateJavascript(
            'walletExtension.onAppResponse("${params.msgType}", ${jsonEncode(result.toJson())})');
      default:
        print('Unknown message from dapp: ${msg['msgType']}');
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      rootBundle
          .loadString('packages/polkawallet_sdk/js_as_extension/dist/main.js')
          .then((String js) {
        setState(() {
          _jsCode = js;
        });
      });
    });
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

        if (_jsInjected) return;
        setState(() {
          _jsInjected = true;
        });

        print('Inject extension js code...');
        _controller.evaluateJavascript(_jsCode);
        print('js code injected');
        if (widget.onExtensionReady != null) {
          widget.onExtensionReady();
        }
      },
      gestureNavigationEnabled: true,
    );
  }
}

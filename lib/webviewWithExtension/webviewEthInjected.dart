import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/payloadData.dart';
import 'package:polkawallet_sdk/consts/settings.dart';
import 'package:polkawallet_sdk/service/eth/rpcApi.dart';
import 'package:polkawallet_sdk/storage/keyringEVM.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewEthInjected extends StatefulWidget {
  WebViewEthInjected(
    this.api,
    this.initialUrl,
    this.keyringEVM, {
    this.onPageFinished,
    this.onExtensionReady,
    this.onWebViewCreated,
    this.onSignRequest,
    this.onConnectRequest,
    this.checkAuth,
  });

  final String initialUrl;
  final PolkawalletApi api;
  final KeyringEVM keyringEVM;
  final Function(String)? onPageFinished;
  final Function? onExtensionReady;
  final Function(WebViewController)? onWebViewCreated;
  final Future<WCCallRequestResult?> Function(Map)? onSignRequest;
  final Future<bool?> Function(DAppConnectParam)? onConnectRequest;
  final bool Function(String)? checkAuth;

  @override
  _WebViewEthInjectedState createState() => _WebViewEthInjectedState();
}

class _WebViewEthInjectedState extends State<WebViewEthInjected> {
  late WebViewController _controller;
  bool _loadingFinished = false;
  bool _signing = false;

  Future<String> _respondToDApp(Map msg, Map res) async {
    print('respond ${msg['name']} to dapp:');
    print(res);
    return _controller.runJavascriptReturningResult(
        'msgFromPolkawallet({name: "${msg['name']}", data: ${jsonEncode(res)}})');
  }

  Future<String> _msgHandler(Map msg) async {
    final res = {...(msg['data'] as Map)};
    res.remove('toNative');

    final uri = Uri.parse(msg['origin']);
    final method = res['method'];
    final isSigningMethod = SigningMethodsEVM.contains(method);
    if (!isSigningMethod) {
      final data = await EvmRpcApi.getRpcCall(
          widget.api.connectedNode?.endpoint ?? '', res);
      if (data['result'] != null) {
        res['result'] = data['result'];
      } else {
        res['error'] = ['unauthorized', 'Rpc call error.'];
      }
      return _respondToDApp(msg, res);
    }
    if (method != 'eth_requestAccounts' &&
        method != 'eth_accounts' &&
        widget.checkAuth != null &&
        !widget.checkAuth!(uri.host)) {
      res['error'] = ['unauthorized', 'wallet accounts unauthorized.'];
      return _respondToDApp(msg, res);
    }

    switch (method) {
      case 'eth_requestAccounts':
      case 'eth_accounts':
        if (_signing) break;
        _signing = true;
        final accept = await widget.onConnectRequest!(DAppConnectParam.fromJson(
            {'id': res['id'].toString(), 'url': msg['origin']}));
        _signing = false;
        if (accept == true) {
          res['result'] = [widget.keyringEVM.current.address];
          return _respondToDApp(msg, res);
        }
        res['error'] = [
          'userRejectedRequest',
          'User denied account authorization.'
        ];
        return _respondToDApp(msg, res);
      case 'metamask_getProviderState':
        final chainId = int.parse(widget.api.connectedNode?.chainId ?? '1');
        res['result'] = {
          'accounts': [widget.keyringEVM.current.address],
          'chainId': '0x${chainId.toRadixString(16)}',
          'isUnlocked': true,
          'networkVersion': '0',
        };
        return _respondToDApp(msg, res);
      case 'eth_chainId':
        final chainId = int.parse(widget.api.connectedNode?.chainId ?? '1');
        // Convert to hex
        res['result'] = '0x${chainId.toRadixString(16)}';
        return _respondToDApp(msg, res);
      case 'eth_sign':
      case 'personal_sign':
      case 'eth_signTypedData':
      case 'eth_signTypedData_v4':
      case 'eth_signTransaction':
      case 'eth_sendTransaction':
        if (_signing) break;
        _signing = true;
        final signed = await widget.onSignRequest!(msg);
        _signing = false;
        if (signed == null) {
          // cancelled
          res['error'] = ['userRejectedRequest', 'User rejected sign request.'];
        } else if (signed.result != null) {
          res['result'] = signed.result;
        } else {
          res['error'] = ['userRejectedRequest', signed.error];
        }
        return _respondToDApp(msg, res);
      default:
        print('Unknown message from dapp: ${msg['msgType']}');
        res['error'] = ['unauthorized', 'Method $method not support.'];
        return _respondToDApp(msg, res);
    }
    return Future(() => "");
  }

  Future<void> _onFinishLoad(String url) async {
    if (_loadingFinished) return;
    setState(() {
      _loadingFinished = true;
    });

    if (widget.onPageFinished != null) {
      widget.onPageFinished!(url);
    }
    print('Page loaded: $url');

    print('Inject dapp js code...');
    final jsCode = await rootBundle.loadString(
        'packages/polkawallet_sdk/js_as_extension/dist/ethereum.js');
    await _controller.runJavascriptReturningResult(jsCode);
    print('js code injected');
    // final List temp = jsonDecode(
    //     await _controller.runJavascriptReturningResult('Object.keys(window);'));

    // temp.forEach((e) => print(e));
    if (widget.onExtensionReady != null) {
      widget.onExtensionReady!();
    }
  }

  Future<void> _launchWalletConnectLink(Uri url) async {
    if (await canLaunchUrl(url)) {
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (err) {
        if (kDebugMode) {
          print(err);
        }
      }
    } else {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: widget.initialUrl,
      javascriptMode: JavascriptMode.unrestricted,
      onWebViewCreated: (WebViewController webViewController) {
        if (widget.onWebViewCreated != null) {
          widget.onWebViewCreated!(webViewController);
        }
        setState(() {
          _controller = webViewController;
        });
      },
      javascriptChannels: <JavascriptChannel>[
        JavascriptChannel(
          name: 'Extension',
          onMessageReceived: (JavascriptMessage message) {
            print('msg from dapp: ${message.message}');
            final msg = jsonDecode(message.message);
            if (msg['path'] != 'extensionRequest') return;
            _msgHandler(msg['data']);
          },
        ),
      ].toSet(),
      // onPageStarted: (String url) {
      //   if (Platform.isAndroid) {
      //     _onFinishLoad(url);
      //   }
      // },
      onPageFinished: (String url) {
        _onFinishLoad(url);
        // if (Platform.isIOS) {
        //   _onFinishLoad(url);
        // }
      },
      gestureNavigationEnabled: true,
      navigationDelegate: (NavigationRequest request) {
        if (request.url.startsWith('wc:')) {
          _launchWalletConnectLink(Uri.parse(request.url));
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
    );
  }
}

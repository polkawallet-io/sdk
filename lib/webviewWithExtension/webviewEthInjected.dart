import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/payloadData.dart';
import 'package:polkawallet_sdk/consts/settings.dart';
import 'package:polkawallet_sdk/service/eth/rpcApi.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/keyringEVM.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewEthInjected extends StatefulWidget {
  WebViewEthInjected(
    this.api,
    this.initialUrl,
    this.keyringEVM, {
    required this.keyring,
    this.onPageFinished,
    this.onExtensionReady,
    this.onWebViewCreated,
    this.onSignRequestEVM,
    this.onSignRequest,
    this.onConnectRequest,
    this.onConnectRequestEVM,
    this.checkAuth,
  });

  final String initialUrl;
  final PolkawalletApi api;
  final KeyringEVM keyringEVM;
  final Keyring keyring;
  final Function(String)? onPageFinished;
  final Function? onExtensionReady;
  final Function(WebViewController)? onWebViewCreated;

  /// onSignRequestEVM handles EVM requests
  final Future<WCCallRequestResult?> Function(Map)? onSignRequestEVM;

  /// onSignBytesRequest & onSignExtrinsicRequest handles Substrate requests
  final Future<ExtensionSignResult?> Function(SignAsExtensionParam)?
      onSignRequest;

  final Future<bool?> Function(DAppConnectParam)? onConnectRequest;
  final Future<bool?> Function(DAppConnectParam)? onConnectRequestEVM;
  final bool Function(String, {bool isEvm})? checkAuth;

  @override
  _WebViewEthInjectedState createState() => _WebViewEthInjectedState();
}

class _WebViewEthInjectedState extends State<WebViewEthInjected> {
  late WebViewController _controller;
  bool _loadingFinished = false;
  bool _signing = false;

  String _currentChainId = '';

  void _showEvmMismatch() {
    showCupertinoDialog(
        context: context,
        builder: (_) {
          return CupertinoAlertDialog(
            title: Text('Network Mismatch'),
            actions: [
              CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Okay'))
            ],
          );
        });
  }

  Future<dynamic> _respondToDApp(Map msg, Map? res) async {
    print('respond ${msg['name']} to dapp:');
    print(res);
    return _controller.runJavaScript(
        'msgFromPolkawallet({name: "${msg['name']}", data: ${res != null ? jsonEncode(res) : null}})');
  }

  Future<dynamic> _msgHandler(Map msg) async {
    if (msg['msgType'] != null) {
      return _msgHandlerSubstrate(msg);
    }

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
        !widget.checkAuth!(uri.host, isEvm: true)) {
      res['error'] = ['unauthorized', 'wallet accounts unauthorized.'];
      return _respondToDApp(msg, res);
    }

    switch (method) {
      case 'eth_requestAccounts':
      case 'eth_accounts':
        if (_signing) break;
        _signing = true;
        final accept = await widget.onConnectRequestEVM!(
            DAppConnectParam.fromJson(
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
      case 'wallet_switchEthereumChain':
        _currentChainId = res['params'][0]['chainId'];
        res['result'] = null;
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
        res['result'] = _currentChainId.isNotEmpty
            ? _currentChainId
            : '0x${chainId.toRadixString(16)}';
        return _respondToDApp(msg, res);
      case 'eth_sign':
      case 'personal_sign':
      case 'eth_signTypedData':
      case 'eth_signTypedData_v4':
      case 'eth_signTransaction':
      case 'eth_sendTransaction':
        if (_signing) break;

        /// the wallet will not send EVM tx if plugin mismatch
        if (method == 'eth_sendTransaction' && _currentChainId.isNotEmpty) {
          _showEvmMismatch();
          break;
        }
        _signing = true;
        final signed = await widget.onSignRequestEVM!(msg);
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

  Future<dynamic> _msgHandlerSubstrate(Map msg) async {
    final uri = Uri.parse(msg['url']);
    if (msg['msgType'] != 'pub(authorize.tab)' &&
        widget.checkAuth != null &&
        !widget.checkAuth!(uri.host)) {
      return _controller.runJavaScript(
          'walletExtension.onAppResponse("${msg['msgType']}${msg['id']}", null, new Error("Rejected"))');
    }

    switch (msg['msgType']) {
      case 'pub(authorize.tab)':
        if (widget.onConnectRequest == null) {
          return _controller.runJavaScript(
              'walletExtension.onAppResponse("${msg['msgType']}${msg['id']}", true)');
        }
        if (_signing) break;
        _signing = true;
        final accept = await widget.onConnectRequest!(
            DAppConnectParam.fromJson({'id': msg['id'], 'url': msg['url']}));
        _signing = false;
        return _controller.runJavaScript(
            'walletExtension.onAppResponse("${msg['msgType']}${msg['id']}", ${accept ?? false}, null)');
      case 'pub(accounts.list)':
      case 'pub(accounts.subscribe)':
        final List<KeyPairData> ls = widget.keyring.keyPairs;
        ls.retainWhere((e) => e.encoding!['content'][1] == 'sr25519');
        final List res = ls.map((e) {
          return {
            'address': e.address,
            'name': e.name,
            'genesisHash': '',
          };
        }).toList();
        return _controller.runJavaScript(
            'walletExtension.onAppResponse("${msg['msgType']}${msg['id']}", ${jsonEncode(res)})');
      case 'pub(bytes.sign)':
        if (_signing) break;
        _signing = true;
        final SignAsExtensionParam param =
            SignAsExtensionParam.fromJson(msg as Map<String, dynamic>);
        final res = await widget.onSignRequest!(param);
        _signing = false;
        if (res == null || res.signature == null) {
          // cancelled
          return _controller.runJavaScript(
              'walletExtension.onAppResponse("${param.msgType}${msg['id']}", null, new Error("Rejected"))');
        }
        return _controller.runJavaScript(
            'walletExtension.onAppResponse("${param.msgType}${msg['id']}", ${jsonEncode(res.toJson())})');
      case 'pub(extrinsic.sign)':
        if (_signing) break;
        _signing = true;
        final SignAsExtensionParam params =
            SignAsExtensionParam.fromJson(msg as Map<String, dynamic>);
        final result = await widget.onSignRequest!(params);
        _signing = false;
        if (result == null || result.signature == null) {
          // cancelled
          return _controller.runJavaScript(
              'walletExtension.onAppResponse("${params.msgType}${msg['id']}", null, new Error("Rejected"))');
        }
        return _controller.runJavaScript(
            'walletExtension.onAppResponse("${params.msgType}${msg['id']}", ${jsonEncode(result.toJson())})');
      default:
        print('Unknown message from dapp: ${msg['msgType']}');
        return Future(() => "");
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

    print('Inject EVM dapp js code...');
    final jsCodeEVM = await rootBundle.loadString(
        'packages/polkawallet_sdk/js_as_extension/dist/ethereum.js');
    await _controller.runJavaScriptReturningResult(jsCodeEVM);
    print('EVM js code injected');
    print('Inject Substrate dapp js code...');
    final jsCode = await rootBundle
        .loadString('packages/polkawallet_sdk/js_as_extension/dist/main.js');
    await _controller.runJavaScriptReturningResult(jsCode);
    print('Substrate js code injected');

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
  void initState() {
    super.initState();

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(
            const PlatformWebViewControllerCreationParams());

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _onFinishLoad(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('wc:')) {
              _launchWalletConnectLink(Uri.parse(request.url));
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Extension',
        onMessageReceived: (JavaScriptMessage message) {
          print('msg from dapp: ${message.message}');
          final msg = jsonDecode(message.message);
          if (msg['path'] != 'extensionRequest') return;
          _msgHandler(msg['data']);
        },
      )
      ..loadRequest(Uri.parse(widget.initialUrl));

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}

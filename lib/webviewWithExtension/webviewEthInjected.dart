import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/payloadData.dart';
import 'package:polkawallet_sdk/consts/settings.dart';
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
    required this.onSwitchEvmChain,
    required this.onEvmRpcCall,
    required this.onAccountEmpty,
    this.onPageFinished,
    this.onExtensionReady,
    this.onWebViewCreated,
    this.onSignRequestEVM,
    this.onSignRequest,
    this.onConnectRequest,
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

  final Future<List<KeyPairData>> Function(DAppConnectParam, {bool isEvm})?
      onConnectRequest;
  final List<KeyPairData> Function(String, {bool isEvm})? checkAuth;
  final Future<bool> Function(String) onSwitchEvmChain;
  final Future<Map> Function(Map) onEvmRpcCall;
  final Future<void> Function(String) onAccountEmpty;

  @override
  _WebViewEthInjectedState createState() => _WebViewEthInjectedState();
}

class _WebViewEthInjectedState extends State<WebViewEthInjected> {
  late WebViewController _controller;
  bool _loadingFinished = false;
  bool _signing = false;

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
      final data = await widget.onEvmRpcCall(res);
      res['result'] = data['result'];
      return _respondToDApp(msg, res);
    }
    final authed = widget.checkAuth!(uri.host, isEvm: true);
    if (method != 'eth_requestAccounts' &&
        method != 'eth_accounts' &&
        authed.isEmpty) {
      res['error'] = ['unauthorized', 'wallet accounts unauthorized.'];
      return _respondToDApp(msg, res);
    }

    switch (method) {
      case 'eth_requestAccounts':
      case 'eth_accounts':
        if (_signing) break;
        _signing = true;

        List<KeyPairData> accountsAuthed = [];
        if (widget.keyringEVM.keyPairs.isEmpty) {
          await widget.onAccountEmpty('evm');
          _signing = false;
        } else if (authed.isNotEmpty) {
          res['result'] = authed.map((e) => e.address).toList();
          _signing = false;
          return _respondToDApp(msg, res);
        } else {
          accountsAuthed = await widget.onConnectRequest!(
              DAppConnectParam.fromJson(
                  {'id': res['id'].toString(), 'url': msg['origin']}),
              isEvm: true);
          _signing = false;
        }

        if (accountsAuthed.isNotEmpty) {
          res['result'] = accountsAuthed.map((e) => e.address).toList();
          return _respondToDApp(msg, res);
        }
        res['error'] = [
          'userRejectedRequest',
          'User denied account authorization.'
        ];
        return _respondToDApp(msg, res);
      case 'wallet_switchEthereumChain':
        bool? accept = false;
        if (widget.keyringEVM.keyPairs.isEmpty) {
          await widget.onAccountEmpty('evm');
        } else {
          if (_signing) break;
          _signing = true;

          accept = await widget.onSwitchEvmChain(res['params'][0]['chainId']);

          _signing = false;
        }

        if (accept != true) {
          res['error'] = ['userRejectedRequest', 'User denied network switch.'];
        }
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
      case 'eth_sign':
      case 'personal_sign':
      case 'eth_signTypedData':
      case 'eth_signTypedData_v4':
      case 'eth_signTransaction':
      case 'eth_sendTransaction':
        if (_signing) break;
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
    final authed = widget.checkAuth!(uri.host);
    if (msg['msgType'] != 'pub(authorize.tab)' &&
        widget.checkAuth != null &&
        authed.isEmpty) {
      return _controller.runJavaScript(
          'walletExtension.onAppResponse("${msg['msgType']}${msg['id']}", null, new Error("Rejected"))');
    }

    switch (msg['msgType']) {
      case 'pub(authorize.tab)':
        if (widget.onConnectRequest == null) {
          return _controller.runJavaScript(
              'walletExtension.onAppResponse("${msg['msgType']}${msg['id']}", true)');
        }

        if (widget.keyring.keyPairs.isEmpty) {
          await widget.onAccountEmpty('substrate');
          return _controller.runJavaScript(
              'walletExtension.onAppResponse("${msg['msgType']}${msg['id']}", false, null)');
        }

        if (_signing) break;
        _signing = true;
        final addressAuthed = authed.isNotEmpty
            ? authed
            : await widget.onConnectRequest!(DAppConnectParam.fromJson(
                {'id': msg['id'], 'url': msg['url']}));
        _signing = false;
        return _controller.runJavaScript(
            'walletExtension.onAppResponse("${msg['msgType']}${msg['id']}", ${addressAuthed.isNotEmpty ?? false}, null)');
      case 'pub(accounts.list)':
      case 'pub(accounts.subscribe)':
        final List res = authed.map((e) {
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
    // if (_loadingFinished) return;
    // setState(() {
    //   _loadingFinished = true;
    // });

    if (widget.onPageFinished != null) {
      widget.onPageFinished!(url);
    }
    print('Page loaded: $url');

    print('Inject EVM dapp js code...');
    final jsCodeEVM = await rootBundle.loadString(
        'packages/polkawallet_sdk/js_as_extension/dist/ethereum.js');
    await _controller.runJavaScript(jsCodeEVM);
    print('EVM js code injected');
    print('Inject Substrate dapp js code...');
    final jsCode = await rootBundle
        .loadString('packages/polkawallet_sdk/js_as_extension/dist/main.js');
    await _controller.runJavaScript(jsCode);
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

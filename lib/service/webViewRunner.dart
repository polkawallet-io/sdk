import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:jaguar/jaguar.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/service/jaguar_flutter_asset.dart';
import 'package:polkawallet_sdk/service/keyring.dart';
// import 'package:polkawallet_sdk/storage/keyring.dart';

class WebViewRunner {
  HeadlessInAppWebView? _web;
  Function? _onLaunched;

  late String _jsCode;
  String? _jsCodeEth;
  Map<String, Function> _msgHandlers = {};
  Map<String, Completer> _msgCompleters = {};
  int _evalJavascriptUID = 0;

  bool _webViewLoaded = false;
  Timer? _webViewReloadTimer;
  PluginType _pluginType = PluginType.Substrate;

  Future<void> launch(
    ServiceKeyring? keyring,
    PluginType pluginType,
    // Keyring keyringStorage,
    Function? onLaunched, {
    String? jsCode,
  }) async {
    /// reset state before webView launch or reload
    _msgHandlers = {};
    _msgCompleters = {};
    _evalJavascriptUID = 0;
    _onLaunched = onLaunched;
    _webViewLoaded = false;
    _pluginType = pluginType;

    _jsCode = jsCode ??
        await rootBundle
            .loadString('packages/polkawallet_sdk/js_api/dist/main.js');
    print('js file loaded');

    if (_web == null) {
      await _startLocalServer();

      _web = new HeadlessInAppWebView(
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(),
        ),
        onWebViewCreated: (controller) {
          print('HeadlessInAppWebView created!');
        },
        onConsoleMessage: (controller, message) {
          print("CONSOLE MESSAGE: " + message.message);
          if (message.messageLevel != ConsoleMessageLevel.LOG) return;

          compute(jsonDecode, message.message).then((msg) {
            final String? path = msg['path'];
            if (_msgCompleters[path!] != null) {
              Completer handler = _msgCompleters[path]!;
              handler.complete(msg['data']);
              if (path.contains('uid=')) {
                _msgCompleters.remove(path);
              }
            }
            if (_msgHandlers[path] != null) {
              Function handler = _msgHandlers[path]!;
              handler(msg['data']);
            }
          });
        },
        onLoadStop: (controller, url) async {
          print('webview loaded');
          if (_webViewLoaded) return;

          _handleReloaded();
          await _startJSCode(keyring);
        },
      );

      await _web!.run();
      _web!.webViewController.loadUrl(
          urlRequest: URLRequest(url: Uri.parse("https://localhost:8080/")));
    } else {
      _tryReload();
    }
  }

  void _tryReload() {
    if (!_webViewLoaded) {
      _web?.webViewController.reload();

      _webViewReloadTimer = Timer(Duration(seconds: 3), _tryReload);
    }
  }

  void _handleReloaded() {
    _webViewReloadTimer?.cancel();
    _webViewLoaded = true;
  }

  Future<void> _startLocalServer() async {
    final cert = await rootBundle
        .load("packages/polkawallet_sdk/lib/ssl/certificate.pem");
    final keys =
        await rootBundle.load("packages/polkawallet_sdk/lib/ssl/keys.pem");
    final security = new SecurityContext()
      ..useCertificateChainBytes(cert.buffer.asInt8List())
      ..usePrivateKeyBytes(keys.buffer.asInt8List());
    // Serves the API at localhost:8080 by default
    final server = Jaguar(securityContext: security);
    server.addRoute(serveFlutterAssets());
    await server.serve(logRequests: false);
  }

  Future<void> _startJSCode(ServiceKeyring? keyring) async {
    // inject js file to webView
    await _web!.webViewController.evaluateJavascript(source: _jsCode);
    if (_pluginType == PluginType.Etherem) {
      _jsCodeEth = _jsCodeEth ??
          await rootBundle
              .loadString('packages/polkawallet_sdk/js_api_eth/dist/main.js');

      await _web!.webViewController.evaluateJavascript(source: _jsCodeEth!);
    }

    _onLaunched!();
  }

  int getEvalJavascriptUID() {
    return _evalJavascriptUID++;
  }

  Future<dynamic> evalJavascript(
    String code, {
    bool wrapPromise = true,
    bool allowRepeat = true,
  }) async {
    // check if there's a same request loading
    if (!allowRepeat) {
      for (String i in _msgCompleters.keys) {
        String call = code.split('(')[0];
        if (i.contains(call)) {
          print('request $call loading');
          return _msgCompleters[i]!.future;
        }
      }
    }

    if (!wrapPromise) {
      final res =
          await _web!.webViewController.evaluateJavascript(source: code);
      return res;
    }

    final c = new Completer();

    final uid = getEvalJavascriptUID();
    final method = 'uid=$uid;${code.split('(')[0]}';
    _msgCompleters[method] = c;

    final script = '$code.then(function(res) {'
        '  console.log(JSON.stringify({ path: "$method", data: res }));'
        '}).catch(function(err) {'
        '  console.log(JSON.stringify({ path: "log", data: err.message }));'
        '});$uid;';
    _web!.webViewController.evaluateJavascript(source: script);

    return c.future;
  }

  Future<NetworkParams?> connectNode(List<NetworkParams> nodes) async {
    final dynamic res = await evalJavascript(
        'settings.connect(${jsonEncode(nodes.map((e) => e.endpoint).toList())})');
    if (res != null) {
      final index = nodes.indexWhere((e) => e.endpoint!.trim() == res.trim());
      return nodes[index > -1 ? index : 0];
    }
    return null;
  }

  Future<void> subscribeMessage(
    String code,
    String channel,
    Function callback,
  ) async {
    addMsgHandler(channel, callback);
    evalJavascript(code);
  }

  void unsubscribeMessage(String channel) {
    print('unsubscribe $channel');
    final unsubCall = 'unsub$channel';
    _web!.webViewController
        .evaluateJavascript(source: 'window.$unsubCall && window.$unsubCall()');
  }

  void addMsgHandler(String channel, Function onMessage) {
    _msgHandlers[channel] = onMessage;
  }

  void removeMsgHandler(String channel) {
    _msgHandlers.remove(channel);
  }
}

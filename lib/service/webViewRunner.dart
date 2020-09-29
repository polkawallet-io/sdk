import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/service/keyring.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

class WebViewRunner {
  FlutterWebviewPlugin _web;
  Function _onLaunched;

  Map<String, Function> _msgHandlers = {};
  Map<String, Completer> _msgCompleters = {};
  int _evalJavascriptUID = 0;

  StreamSubscription _subscription;

  Future<void> launch(
    ServiceKeyring keyring,
    Keyring keyringStorage,
    Function onLaunched, {
    String jsCode,
  }) async {
    /// reset state before webView launch or reload
    _msgHandlers = {};
    _msgCompleters = {};
    _evalJavascriptUID = 0;
    _onLaunched = onLaunched;

    final needLaunch = _web == null;

    _web = FlutterWebviewPlugin();

    /// cancel another plugin's listener before launch
    if (_subscription != null) {
      _subscription.cancel();
    }
    _subscription = _web.onStateChanged.listen((viewState) async {
      if (viewState.type == WebViewState.finishLoad) {
        print('webview loaded');
        final js = jsCode ??
            await rootBundle
                .loadString('packages/polkawallet_sdk/js_api/dist/main.js');

        print('js file loaded');
        await _startJSCode(js, keyring, keyringStorage);
      }
    });

    if (!needLaunch) {
      _web.reload();
      return;
    }

    _web.launch(
      'about:blank',
      javascriptChannels: [
        JavascriptChannel(
            name: 'PolkaWallet',
            onMessageReceived: (JavascriptMessage message) {
              print('received msg: ${message.message}');
              compute(jsonDecode, message.message).then((msg) {
                final String path = msg['path'];
                if (_msgCompleters[path] != null) {
                  Completer handler = _msgCompleters[path];
                  handler.complete(msg['data']);
                  if (path.contains('uid=')) {
                    _msgCompleters.remove(path);
                  }
                }
                if (_msgHandlers[path] != null) {
                  Function handler = _msgHandlers[path];
                  handler(msg['data']);
                }
              });
            }),
      ].toSet(),
      ignoreSSLErrors: true,
//        withLocalUrl: true,
//        localUrlScope: 'lib/polkadot_js_service/dist/',
      hidden: true,
    );
  }

  Future<void> _startJSCode(
    String js,
    ServiceKeyring keyring,
    Keyring keyringStorage,
  ) async {
    // inject js file to webView
    await _web.evalJavascript(js);

    // load accounts to webView from storage
    final res = await keyring.injectKeyPairsToWebView(
        keyringStorage.keyPairs, keyringStorage.store.ss58List);
    if (res != null) {
      keyringStorage.store.updatePubKeyAddressMap(Map<String, Map>.from(res));
    }

    _onLaunched();
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
          return _msgCompleters[i].future;
        }
      }
    }

    if (!wrapPromise) {
      String res = await _web.evalJavascript(code);
      return res;
    }

    Completer c = new Completer();

    String method = 'uid=${getEvalJavascriptUID()};${code.split('(')[0]}';
    _msgCompleters[method] = c;

    String script = '$code.then(function(res) {'
        '  PolkaWallet.postMessage(JSON.stringify({ path: "$method", data: res }));'
        '}).catch(function(err) {'
        '  PolkaWallet.postMessage(JSON.stringify({ path: "log", data: err.message }));'
        '})';
    _web.evalJavascript(script);

    return c.future;
  }

  Future<String> connectNode(NetworkParams params) async {
    final res = await evalJavascript('settings.connect("${params.endpoint}")');
    return res;
  }

  Future<NetworkParams> connectNodeAll(List<NetworkParams> nodes) async {
    final String res = await evalJavascript(
        'settings.connectAll(${jsonEncode(nodes.map((e) => e.endpoint).toList())})');
    if (res != null) {
      final node = nodes.firstWhere((e) => e.endpoint == res);
      return node;
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

  Future<void> unsubscribeMessage(String channel) async {
    print('unsubscribe $channel');
    _web.evalJavascript('unsub$channel()');
  }

  void addMsgHandler(String channel, Function onMessage) {
    _msgHandlers[channel] = onMessage;
  }

  void removeMsgHandler(String channel) {
    _msgHandlers.remove(channel);
  }
}

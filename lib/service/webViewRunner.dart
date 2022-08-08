import 'dart:async';
import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';

class WebViewRunner {
  HeadlessInAppWebView? _web;
  InAppLocalhostServer? _localhostServer;
  Function? _onLaunched;

  String? _jsCode;
  late String _jsCodeEth;
  Map<String, Function> _msgHandlers = {};
  Map<String, Completer> _msgCompleters = {};
  Map<String, Function> _reloadHandlers = {};
  Map<String, String> _msgJavascript = {};
  int _evalJavascriptUID = 0;

  bool webViewLoaded = false;
  int jsCodeStarted = -1;

  bool _webViewOOMReload = false;

  Future<void> launch(
    Function? onLaunched, {
    String? jsCode,
    Function? socketDisconnectedAction,
  }) async {
    /// reset state before webView launch or reload
    _msgHandlers = {};
    _msgCompleters = {};
    _msgJavascript = {};
    _reloadHandlers = {};
    _evalJavascriptUID = 0;
    if (onLaunched != null) {
      _onLaunched = onLaunched;
    }
    webViewLoaded = false;
    _webViewOOMReload = false;
    jsCodeStarted = -1;

    _jsCode = jsCode;
    // TODO: always load eth js for evm keyring (while evm online)
    // _jsCodeEth = await rootBundle
    //     .loadString('packages/polkawallet_sdk/js_api_eth/dist/main.js');
    // print('js eth file loaded');

    if (_web == null) {
      await _startLocalServer();

      _web = new HeadlessInAppWebView(
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(clearCache: true),
          android: AndroidInAppWebViewOptions(useOnRenderProcessGone: true),
        ),
        androidOnRenderProcessGone: (webView, detail) async {
          if (_web?.webViewController == webView) {
            webViewLoaded = false;
            _webViewOOMReload = true;
            await _web?.webViewController.clearCache();
            await _web?.webViewController.reload();
          }
        },
        initialUrlRequest: URLRequest(
            url: Uri.parse(
                "http://localhost:8080/packages/polkawallet_sdk/assets/index.html")),
        onWebViewCreated: (controller) {
          print('HeadlessInAppWebView created!');
        },
        onConsoleMessage: (controller, message) {
          print("CONSOLE MESSAGE: " + message.message);
          if (jsCodeStarted < 0) {
            try {
              final msg = jsonDecode(message.message);
              if (msg['path'] == 'log') {
                if (message.message.contains('js loaded')) {
                  jsCodeStarted = 1;
                } else {
                  jsCodeStarted = 0;
                }
              }
            } catch (err) {
              // ignore
            }
          }
          if (message.message.contains("WebSocket is not connected") &&
              socketDisconnectedAction != null) {
            socketDisconnectedAction();
          }
          if (message.messageLevel != ConsoleMessageLevel.LOG) return;

          try {
            var msg = jsonDecode(message.message);

            final String path = msg['path']!;
            if (_msgCompleters[path] != null) {
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

            if (path == 'log') {
              final String? call = msg['data']?['call'];
              final String? error = msg['data']?['error'];
              if (call != null && _msgCompleters[call] != null) {
                Completer handler = _msgCompleters[call]!;
                handler.completeError(error ?? "$call error");
                if (call.contains('uid=')) {
                  _msgCompleters.remove(call);
                }
              }
            }

            if (_msgJavascript[path.split(";")[1]] != null) {
              _msgJavascript.remove(path.split(";")[1]);
            }
          } catch (_) {
            // ignore
          }
        },
        onLoadStop: (controller, url) async {
          print('webview loaded $url');
          if (webViewLoaded) return;

          webViewLoaded = true;
          await _startJSCode();
        },
        onLoadError: (controller, url, code, message) {
          print("webview restart");
          _web = null;
          launch(null,
              jsCode: jsCode,
              socketDisconnectedAction: socketDisconnectedAction);
        },
      );

      await _web?.dispose();
      await _web?.run();
    } else {
      _tryReload();
    }
  }

  void _tryReload() {
    if (!webViewLoaded) {
      _web?.webViewController.reload();
    }
  }

  Future<void> _startLocalServer() async {
    _localhostServer?.close();
    _localhostServer = new InAppLocalhostServer();
    await _localhostServer!.start();
  }

  Future<void> _startJSCode() async {
    // inject js file to webView
    // TODO: no eth injection before evm online
    if (_jsCode != null) {
      await _web!.webViewController.evaluateJavascript(source: _jsCode!);
    }
    // await _web!.webViewController.evaluateJavascript(source: _jsCodeEth);

    _onLaunched!();
    _reloadHandlers.forEach((_, value) {
      value();
    });
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
        '  console.log(JSON.stringify({ path: "log", data: {call: "$method", error: err.message} }));'
        '});';
    _web!.webViewController.evaluateJavascript(source: script);
    _msgJavascript[code.split('(')[0]] = script;

    return c.future;
  }

  Future<NetworkParams?> connectNode(List<NetworkParams> nodes) async {
    final isAvatarSupport = (await evalJavascript(
            'settings.connectAll ? {}:null',
            wrapPromise: false)) !=
        null;
    final dynamic res = await (isAvatarSupport
        ? evalJavascript(
            'settings.connectAll(${jsonEncode(nodes.map((e) => e.endpoint).toList())})')
        : evalJavascript(
            'settings.connect(${jsonEncode(nodes.map((e) => e.endpoint).toList())})'));
    if (res != null) {
      final index = nodes.indexWhere((e) => e.endpoint!.trim() == res.trim());
      if (_webViewOOMReload) {
        print(
            "webView OOM Reload evaluateJavascript====\n${_msgJavascript.keys.toString()}");
        _msgJavascript.forEach((key, value) {
          _web!.webViewController.evaluateJavascript(source: value);
        });
        _msgJavascript = {};
        _webViewOOMReload = false;
      }
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

  void subscribeReloadAction(String reloadKey, Function reloadAction) {
    _reloadHandlers[reloadKey] = reloadAction;
  }

  void unsubscribeReloadAction(String reloadKey) {
    _reloadHandlers.remove(reloadKey);
  }
}

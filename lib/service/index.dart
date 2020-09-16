import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/service/account.dart';
import 'package:polkawallet_sdk/service/keyring.dart';
import 'package:polkawallet_sdk/service/setting.dart';
import 'package:polkawallet_sdk/service/staking.dart';
import 'package:polkawallet_sdk/service/tx.dart';
import 'package:polkawallet_sdk/service/uos.dart';
import 'package:polkawallet_sdk/storage/localStorage.dart';
import 'package:polkawallet_sdk/utils/localStorage.dart';

class SubstrateService {
  SubstrateService();

  final KeyringStorage storage = KeyringStorage();
  final LocalStorage storageOld = LocalStorage();

  NetworkParams connectedNode;

  ServiceKeyring keyring;
  ServiceSetting setting;
  ServiceAccount account;
  ServiceTx tx;

  ServiceStaking staking;
  ServiceUOS uos;

  Map<String, Function> _msgHandlers = {};
  Map<String, Completer> _msgCompleters = {};
  FlutterWebviewPlugin _web;
  int _evalJavascriptUID = 0;

  void init() {
    keyring = ServiceKeyring(this);
    keyring.loadKeyPairsFromStorage();

    setting = ServiceSetting(this);
    account = ServiceAccount(this);
    tx = ServiceTx(this);
    staking = ServiceStaking(this);
    uos = ServiceUOS(this);

    launchWebview();
  }

//  Future<void> _checkJSCodeUpdate() async {
//    // check js code update
//    final network = store.settings.endpoint.info;
//    final jsVersion = await WalletApi.fetchPolkadotJSVersion(network);
//    final bool needUpdate =
//        await UI.checkJSCodeUpdate(context, jsVersion, network);
//    if (needUpdate) {
//      await UI.updateJSCode(context, jsStorage, network, jsVersion);
//    }
//  }

  void _startJSCode(String js) {
    // inject js file to webView
    _web.evalJavascript(js);

    // load accounts to webView from storage
    keyring.injectKeyPairsToWebView();
  }

  Future<void> launchWebview({bool customNode = false}) async {
//    _msgHandlers = {'txStatusChange': store.account.setTxStatus};

    _evalJavascriptUID = 0;
    _msgCompleters = {};

//    await _checkJSCodeUpdate();
    if (_web != null) {
      _web.reload();
      return;
    }

    _web = FlutterWebviewPlugin();

    _web.onStateChanged.listen((viewState) async {
      if (viewState.type == WebViewState.finishLoad) {
        String network = 'kusama';
        print('webview loaded for network $network');
        rootBundle
            .loadString('packages/polkawallet_sdk/js_api/dist/main.js')
            .then((String js) {
          print('js file loaded');
          _startJSCode(js);
        });
      }
    });

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
    final String res =
        await evalJavascript('settings.connect("${params.endpoint}")');
    if (res != null) {
      connectedNode = params;
      // update pubKeyAddress map after node connected,
      // so we can have the correct address format
      if (connectedNode != null) {
        keyring.updatePubKeyAddressMap();
      }
    }
    return res;
  }

  Future<NetworkParams> connectNodeAll(List<NetworkParams> nodes) async {
    final String res = await evalJavascript(
        'settings.connectAll(${jsonEncode(nodes.map((e) => e.endpoint).toList())})');
    if (res != null) {
      final node = nodes.firstWhere((e) => e.endpoint == res);
      connectedNode = node;
      // update pubKeyAddress map after node connected,
      // so we can have the correct address format
      if (connectedNode != null) {
        keyring.updatePubKeyAddressMap();
      }
      return node;
    }
    return null;
  }

  Future<void> disconnect() async {
    _web.close();
    _web.dispose();
    connectedNode = null;
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

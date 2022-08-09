import 'package:flutter_inappwebview/flutter_inappwebview.dart';

///Single instance
class LocalServer {
  final InAppLocalhostServer? _localhostServer;
  Future<void> startLocalServer() async {
    await _localhostServer?.close();
    await _localhostServer?.start();
  }

  LocalServer._internal(this._localhostServer);
  factory LocalServer() => _instance;

  static late final LocalServer _instance =
      LocalServer._internal(InAppLocalhostServer());

  static LocalServer getInstance() => _instance;
}

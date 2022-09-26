import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

///Single instance
class LocalServer {
  final InAppLocalhostServer? _localhostServer;
  Future<void> startLocalServer() async {
    if (_localhostServer?.isRunning() == true) {
      HttpClient client = HttpClient();
      HttpClientRequest? request;
      try {
        request = await client.getUrl(Uri.parse('http://localhost:8080/'));
      } catch (error) {
        debugPrint(error.toString());
      }
      final response = await request?.close();
      client.close();
      if (response?.statusCode == 200) {
        return;
      }
    }
    await _localhostServer?.close();
    await _localhostServer?.start();
  }

  LocalServer._internal(this._localhostServer);
  factory LocalServer() => _instance;

  static late final LocalServer _instance =
      LocalServer._internal(InAppLocalhostServer());

  static LocalServer getInstance() => _instance;
}

import 'dart:convert';

import 'package:http/http.dart';

const post_headers = {"Content-type": "application/json", "Accept": "*/*"};

class EvmRpcApi {
  static Future<Map> getRpcCall(String endpoint, Map payload) async {
    final url = '$endpoint';
    try {
      final res = await post(Uri.parse(url),
          body: jsonEncode(payload), headers: post_headers);
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map;
    } catch (err) {
      print(err);
      return {};
    }
  }
}

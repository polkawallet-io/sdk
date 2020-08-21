import 'package:flutter_test/flutter_test.dart';

import 'package:polkawallet_sdk/polkawallet_sdk.dart';

void main() {
  group('sdk test', () {
    test('init sdk', () async {
      final sdk = WalletSDK();
      expect(sdk.isReady, false);
      expect(sdk.isConnected, false);
      expect(sdk.api, isNull);
    });
  });
}

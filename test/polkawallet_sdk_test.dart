import 'package:flutter_test/flutter_test.dart';

import 'package:polkawallet_sdk/polkawallet_sdk.dart';
// import 'package:polkawallet_sdk/service/account.dart';
// import 'package:polkawallet_sdk/service/index.dart';
// import 'package:polkawallet_sdk/storage/keyring.dart';
// import 'package:polkawallet_sdk/storage/types/keyPairData.dart';

void main() {
  // const testKeystore =
  //     '{"pubKey":"0xcc597bd2e7eda5094d6aa462523b629a502db6cc71a6ae0e9b158d9e42c6c462","mnemonic":"welcome clinic duck mom connect heart poet admit vendor robot group vacuum","rawSeed":"","address":"15cwMLiH57HvrqBfMYpt5AgGrb5SAUKx7XQUcHnBSs2DAsGt","encoded":"taoH2SolrO8UhraK1JxuNW9AcMMPY5UXMTJjlcpuyEEAgAAAAQAAAAgAAADdvrSwzB9yIFQ7ZCHQoQQV93zLhlAiZlits1CX2hFNm3/zPjYW63U7NzoF76UU4hUvyUTmrvT/K37v0zQ1eFrXwXvc2fmKFJ17qSR2oDvHfuCb+ruCsSrx/UsGtNLbzyCiomVYGMvRh/EzHEfBQO4jGaDi4Sq5++8QE2vuDUTePF8WsVSb5L9N30SFuNQ1YiTH7XBRG9zQhQTofLl0","encoding":{"content":["pkcs8","sr25519"],"type":["scrypt","xsalsa20-poly1305"],"version":"3"},"meta":{}}';

  group('sdk test', () {
    test('init sdk', () async {
      final sdk = WalletSDK();
      expect(sdk.api, null);
    });

    // test('account test', () async {
    //   KeyPairData kdydata = KeyPairData.fromJson(jsonDecode(testKeystore));
    //   final account = ServiceAccount(SubstrateService());
    //   var decoded = await account.decodeAddress([kdydata.address]);
    //   expect(decoded![kdydata.pubKey], kdydata.address);
    // });
  });
}

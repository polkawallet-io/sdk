function expect(actual, matcher) {
  if (actual !== matcher) {
    throw new Error(`expect ${matcher}, got ${actual}`);
  }
}

async function runSettingsTest() {
  console.log("test connect");
  const endpoint = "wss://kusama-1.polkawallet.io:9944";
  const connected = await settings.connect([endpoint]);
  expect(connected, endpoint);
  expect(!!api, true);

  console.log("test get consts");
  const constants = await settings.getNetworkConst(api);
  expect(
    constants.babe.epochDuration.toHuman(),
    api.consts.babe.epochDuration.toHuman()
  );

  console.log("settings tests passed.");
}

const testKeystore =
  '{"pubKey":"0xcc597bd2e7eda5094d6aa462523b629a502db6cc71a6ae0e9b158d9e42c6c462","mnemonic":"welcome clinic duck mom connect heart poet admit vendor robot group vacuum","rawSeed":"","address":"15cwMLiH57HvrqBfMYpt5AgGrb5SAUKx7XQUcHnBSs2DAsGt","encoded":"taoH2SolrO8UhraK1JxuNW9AcMMPY5UXMTJjlcpuyEEAgAAAAQAAAAgAAADdvrSwzB9yIFQ7ZCHQoQQV93zLhlAiZlits1CX2hFNm3/zPjYW63U7NzoF76UU4hUvyUTmrvT/K37v0zQ1eFrXwXvc2fmKFJ17qSR2oDvHfuCb+ruCsSrx/UsGtNLbzyCiomVYGMvRh/EzHEfBQO4jGaDi4Sq5++8QE2vuDUTePF8WsVSb5L9N30SFuNQ1YiTH7XBRG9zQhQTofLl0","encoding":{"content":["pkcs8","sr25519"],"type":["scrypt","xsalsa20-poly1305"],"version":"3"},"meta":{}}';

async function runKeyringTest() {
  console.log("init keys from json");
  const initialAcc = await keyring.initKeys([JSON.parse(testKeystore)], [0, 2]);
  expect(
    initialAcc[0][
      "0xcc597bd2e7eda5094d6aa462523b629a502db6cc71a6ae0e9b158d9e42c6c462"
    ],
    "15cwMLiH57HvrqBfMYpt5AgGrb5SAUKx7XQUcHnBSs2DAsGt"
  );

  console.log("generate mnemonic");
  const mnemonic = await keyring.gen();
  expect(mnemonic.mnemonic.split(" ").length, 12);

  console.log("import account from mnemonic");
  const sr25519 = "sr25519";
  const password = "a111111";
  const acc = await keyring.recover(
    "mnemonic",
    sr25519,
    mnemonic.mnemonic,
    password
  );
  expect(acc.pubKey.length, 66);
  expect(acc.mnemonic, mnemonic.mnemonic);
  expect(acc.encoding.content[1], sr25519);

  console.log("import account from raw seed");
  const acc2 = await keyring.recover("rawSeed", sr25519, "Alice", password);
  expect(acc2.pubKey.length, 66);
  expect(acc2.address, "13iz1UvC8XMnHTW2wgoG7SxUhNgbp7trCgjxcuqTne9bGMQX");
  expect(acc2.encoding.content[1], sr25519);

  console.log("import account from json");
  const acc3 = await keyring.recover(
    "keystore",
    sr25519,
    testKeystore,
    password
  );
  expect(acc3.pubKey.length, 66);
  expect(acc3.address, "15cwMLiH57HvrqBfMYpt5AgGrb5SAUKx7XQUcHnBSs2DAsGt");
  expect(acc3.encoding.content[1], sr25519);

  console.log("check derive path");
  const deriveError = await keyring.checkDerivePath("Alice", "", sr25519);
  expect(deriveError, null);
  const deriveError1 = await keyring.checkDerivePath(
    "Alice",
    "//test",
    sr25519
  );
  expect(deriveError1, null);
  const deriveError2 = await keyring.checkDerivePath(
    "Alice",
    "//test/wallet",
    sr25519
  );
  expect(deriveError2, null);
  const deriveError3 = await keyring.checkDerivePath(
    "Alice",
    "test//",
    sr25519
  );
  expect(true, !!deriveError3);
  const deriveError4 = await keyring.checkDerivePath(
    "Alice",
    "//test",
    "ed25519"
  );
  expect(deriveError4, null);
  const deriveError5 = await keyring.checkDerivePath(
    "Alice",
    "/test",
    "ed25519"
  );
  expect(true, !!deriveError5);

  console.log("generate icons from address");
  const icon1 = await account.genIcons([acc.address]);
  expect(icon1[0][0], acc.address);
  expect(!!icon1[0][1].match("svg"), true);

  console.log("generate icons from pubKey");
  const icon2 = await account.genPubKeyIcons([acc.pubKey]);
  expect(icon2[0][0], acc.pubKey);
  expect(!!icon2[0][1].match("svg"), true);

  console.log("encode address");
  const encoded = await account.encodeAddress([acc.pubKey], [0, 2]);
  expect(encoded[0][acc.pubKey], acc.address);
  console.log("decode address");
  const decoded = await account.decodeAddress([acc.address]);
  expect(decoded[acc.pubKey], acc.address);

  console.log("check password");
  const passCheck = await keyring.checkPassword(acc.pubKey, "b111111");
  expect(passCheck, null);
  const passCheck2 = await keyring.checkPassword(acc.pubKey, password);
  expect(passCheck2.success, true);

  console.log("change password");
  const passNew = "c111111";
  const passChangeRes = await keyring.changePassword(
    acc.pubKey,
    password,
    passNew
  );
  expect(passChangeRes.pubKey, acc.pubKey);
  const passCheck3 = await keyring.checkPassword(acc.pubKey, password);
  expect(passCheck3, null);
  const passCheck4 = await keyring.checkPassword(acc.pubKey, passNew);
  expect(passCheck4.success, true);

  console.log("keyring tests passed.");
}

async function runAccountTest() {
  console.log("query account bonded");
  const testKey =
    "0xe611c2eced1b561183f88faed0dd7d88d5fafdf16f5840c63ec36d8c31136f61";
  const testAddr = "HmyonjFVFZyg1mRjRvohVGRw9ouFDRoQ5ea9nDfH2Yi44qQ";
  const bonded = await account.queryAccountsBonded(api, [testKey]);
  expect(bonded[0][0], testKey);
  expect(bonded[0].length, 3);

  console.log("query balance");
  const balance = await account.getBalance(api, testAddr);
  expect(balance.accountId.toHuman(), testAddr);
  expect(parseFloat(balance.accountNonce.toHuman()) > 0, true);
  expect(parseFloat(balance.availableBalance.toHuman()) > 0, true);
  expect(parseFloat(balance.freeBalance.toHuman()) > 0, true);

  console.log("query info of address");
  const addr2 = "HSNBs8VHxcZiqz9NfSQq2YaznTa8BzSvuEWVe4uTihcGiQN";
  const info = await account.getAccountIndex(api, [addr2]);
  expect(info[0].accountId.toString(), addr2);
  expect(info[0].identity.display, "Acala Foundation");
  expect(info[0].identity.web, "https://acala.network");
  expect(info[0].identity.judgements.length > 0, true);

  console.log("account tests passed.");
}

async function runTests() {
  // keyring api run without network
  await runKeyringTest();
  // run settings api to connect to node
  await runSettingsTest();
  // run other tests
  await runAccountTest();

  console.log("all tests passed.");
}
window.runTests = runTests;

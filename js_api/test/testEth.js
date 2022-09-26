((window) => {
  function expect(actual, matcher) {
    if (actual !== matcher) {
      throw new Error(`expect ${matcher}, got ${actual}`);
    }
  }

  async function runSettingsTestETH() {
    console.log("test connect");
    const endpoint = "wss://kusama.api.onfinality.io/public-ws";
    const connected = await settings.connect([endpoint]);
    expect(connected, endpoint);
    expect(!!api, true);

    console.log("test get consts");
    const constants = await settings.getNetworkConst(api);
    expect(constants.babe.epochDuration.toHuman(), api.consts.babe.epochDuration.toHuman());

    console.log("settings tests passed.");
  }

  const testKeystoreETH = {
    address: "634dbe93a30148af3eb54e92a8ebfb852d1be50b",
    id: "72d15c27-ee38-415f-9e19-dc84ffb3a22d",
    version: 3,
    Crypto: {
      cipher: "aes-128-ctr",
      cipherparams: { iv: "096257c41b1df3a7112a91c08b1493e6" },
      ciphertext: "0206a8ee03e9b0344aefffea1761703312015714df503976727a152b02cce629",
      kdf: "scrypt",
      kdfparams: { salt: "4e7f6e1fc953833472128462092eec42ac58040b1673b9112512acbcbf6e6d4b", n: 131072, dklen: 32, p: 1, r: 8 },
      mac: "633c5b6fef097822a454743fd36f9fc674c6d38355b4bedbfdcafdb1518ab1fd",
    },
    "x-ethers": {
      client: "ethers.js",
      gethFilename: "UTC--2021-09-26T07-27-09.0Z--634dbe93a30148af3eb54e92a8ebfb852d1be50b",
      mnemonicCounter: "2db575fa106234a5e2ff7b6b78940046",
      mnemonicCiphertext: "a147c6e8cfd9d01eb3412708191996d0",
      path: "m/44'/60'/0'/0/0",
      locale: "en",
      version: "0.1",
    },
  };
  const testMnemonicETH = "clown trash dish duty expire select announce nothing winner pepper scorpion until";
  const testAddressETH = "0x634DbE93A30148aF3eB54E92a8Ebfb852D1Be50B";
  const testPKeyETH = "0xac2920c6d04d70f70aaaa541f61e2efaaa89a791e95e62505daa7b67593d87b1";
  const derivePath1 = "m/44'/60'/0'/0/1";
  const testAddress1ETH = "0x015d775B11761d78637801E1f166019Ca147B5BE";
  const testPKey1ETH = "0x5caf995633bac90804739bd0410ca151e397a8c03af364446d58af7a55d11040";
  async function runKeyringTestETH() {
    console.log("generate mnemonic");
    const mnemonicGen = await eth.keyring.gen();
    expect(mnemonicGen.mnemonic.split(" ").length, 12);
    expect(!!mnemonicGen.address.match("0x"), true);
    expect(!!mnemonicGen.svg.match("<svg"), true);
    const mnemonic = await eth.keyring.gen(testMnemonicETH);
    expect(mnemonic.address, testAddressETH);
    const mnemonic1 = await eth.keyring.gen(testMnemonicETH, 1);
    expect(mnemonic1.address, testAddress1ETH);

    console.log("get address from mnemonic/privateKey");
    const mnemonic2 = await eth.keyring.addressFromMnemonic(testMnemonicETH);
    expect(mnemonic2.address, testAddressETH);
    const mnemonic3 = await eth.keyring.addressFromMnemonic(testMnemonicETH, derivePath1);
    expect(mnemonic3.address, testAddress1ETH);
    const mnemonic4 = await eth.keyring.addressFromPrivateKey(testPKeyETH);
    expect(mnemonic4.address, testAddressETH);
    const mnemonic5 = await eth.keyring.addressFromPrivateKey(testPKey1ETH);
    expect(mnemonic5.address, testAddress1ETH);

    console.log("import account from mnemonic");
    const password = "a111111";
    console.log(new Date().toLocaleString());
    const acc = await eth.keyring.recover("mnemonic", testMnemonicETH, null, password);
    console.log(new Date().toLocaleString());
    expect(acc.mnemonic, testMnemonicETH);
    expect(acc.address, testAddressETH);
    expect("0x" + JSON.parse(acc.keystore).address, testAddressETH.toLowerCase());
    const acc1 = await eth.keyring.recover("mnemonic", testMnemonicETH, derivePath1, password);
    expect(acc1.mnemonic, testMnemonicETH);
    expect(acc1.address, testAddress1ETH);
    expect("0x" + JSON.parse(acc1.keystore).address, testAddress1ETH.toLowerCase());

    console.log("import account from privateKey");
    console.log(new Date().toLocaleString());
    const acc2 = await eth.keyring.recover("privateKey", testPKeyETH, null, password);
    console.log(new Date().toLocaleString());
    expect(acc2.privateKey, testPKeyETH);
    expect(acc2.address, testAddressETH);
    expect("0x" + JSON.parse(acc2.keystore).address, testAddressETH.toLowerCase());
    const acc3 = await eth.keyring.recover("privateKey", testPKey1ETH, null, password);
    expect(acc3.privateKey, testPKey1ETH);
    expect(acc3.address, testAddress1ETH);
    expect("0x" + JSON.parse(acc3.keystore).address, testAddress1ETH.toLowerCase());

    console.log("import account from json");
    const acc4 = await eth.keyring.recover("keystore", JSON.stringify(testKeystoreETH), null, password);
    expect(acc4.address, testAddressETH);
    expect("0x" + JSON.parse(acc4.keystore).address, testAddressETH.toLowerCase());
    const acc5 = await eth.keyring.recover("keystore", JSON.stringify(testKeystoreETH), null, password + "xx");
    expect(acc5.address === testAddressETH, false);
    expect(acc5.keystore, undefined);

    console.log("sign message / verify signature");
    const message = "Hello world, my tests.";
    const signed = await eth.keyring.signMessage(message, acc.address, password);
    expect(signed.address, testAddressETH);
    expect(signed.pubKey, acc.pubKey);
    const signatureCheck = await eth.keyring.verifySignature(message, signed.signature);
    expect(signatureCheck.signer, testAddressETH);
    const signatureCheck1 = await eth.keyring.verifySignature(message + "msg changed", signed.signature);
    expect(signatureCheck1.signer === testAddressETH, false);

    console.log("generate icons from address");
    const icon1 = await eth.account.genIcons([testAddressETH]);
    expect(icon1[0][0], testAddressETH);
    expect(icon1[0][1], mnemonic2.svg);
    const icon2 = await eth.account.genIcons([testAddress1ETH]);
    expect(icon2[0][0], testAddress1ETH);
    expect(icon2[0][1], mnemonic3.svg);

    console.log("check password");
    const passCheck1 = await eth.keyring.checkPassword(acc.address, password);
    expect(passCheck1.success, true);
    const passCheck2 = await eth.keyring.checkPassword(acc.address, password + "xx");
    expect(passCheck2.success, false);
    expect(passCheck2.error, "invalid password");

    console.log("change password");
    const passNew = "c111111";
    const changed = await eth.keyring.changePassword(acc.address, password, passNew);
    expect(changed.pubKey, acc.pubKey);
    expect(changed.address, acc.address);
    const passCheck3 = await eth.keyring.checkPassword(changed.address, password);
    expect(passCheck3.success, false);
    expect(passCheck3.error, "invalid password");
    const passCheck4 = await eth.keyring.checkPassword(changed.address, passNew);
    expect(passCheck4.success, true);

    console.log("keyring tests passed.");
  }

  async function runTestsETH() {
    // keyring api run without network
    await runKeyringTestETH();

    console.log("all tests passed.");
  }
  window.runTestsETH = runTestsETH;
})(window);

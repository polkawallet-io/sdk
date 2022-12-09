import { keyExtractSuri, mnemonicGenerate, mnemonicValidate, cryptoWaitReady, signatureVerify, encodeAddress } from "@polkadot/util-crypto";
import { hexToU8a, u8aToHex } from "@polkadot/util";
import { parseQrCode, getSigner, makeTx, getSubmittable } from "../utils/QrSigner";
import gov from "./gov";
import metaDataMap from "../constants/networkMetadata";
import { Metadata, TypeRegistry } from "@polkadot/types";
import { wrapBytes, unwrapBytes } from "@polkadot/extension-dapp/wrapBytes";
import { Keyring } from "@polkadot/keyring";
import { KeypairType } from "@polkadot/util-crypto/types";
import { KeyringPair, KeyringPair$Json } from "@polkadot/keyring/types";
import { ApiPromise, SubmittableResult } from "@polkadot/api";
import { SubmittableExtrinsic } from "@polkadot/api/types";
import { ITuple } from "@polkadot/types/types";
import { DispatchError } from "@polkadot/types/interfaces";
import account from "./account";
let keyring = new Keyring({ ss58Format: 0, type: "sr25519" });

/**
 * Generate a set of new mnemonic.
 */
async function gen(mnemonic: string, ss58Format: number, cryptoType: KeypairType, derivePath: string) {
  const key = mnemonic || mnemonicGenerate();
  if (!mnemonicValidate(key)) return null;

  const keyPair = keyring.addFromMnemonic(key + (derivePath || ""), {}, cryptoType || "sr25519");
  const address = encodeAddress(keyPair.publicKey, ss58Format || 0);
  const icons = await account.genIcons([address]);
  return {
    mnemonic: key,
    address,
    svg: icons[0][1],
  };
}

/**
 * mnemonic validate.
 */
async function checkMnemonicValid(mnemonic: string) {
  return mnemonicValidate(mnemonic);
}

/**
 * get address and avatar from mnemonic.
 */
async function addressFromMnemonic(mnemonic: string, ss58Format: number, cryptoType: KeypairType, derivePath: string) {
  let keyPair: KeyringPair;
  try {
    keyPair = keyring.addFromMnemonic(mnemonic + (derivePath || ""), {}, cryptoType);
    const address = encodeAddress(keyPair.publicKey, ss58Format);
    const icons = await account.genIcons([address]);
    return {
      address,
      svg: icons[0][1],
    };
  } catch (err) {
    return { error: err.message };
  }
}

/**
 * get address and avatar from rawSeed.
 */
async function addressFromRawSeed(rawSeed: string, ss58Format: number, cryptoType: KeypairType, derivePath: string) {
  let keyPair: KeyringPair;
  try {
    keyPair = keyring.addFromUri(rawSeed + (derivePath || ""), {}, cryptoType);
    const address = encodeAddress(keyPair.publicKey, ss58Format);
    const icons = await account.genIcons([address]);
    return {
      address,
      svg: icons[0][1],
    };
  } catch (err) {
    return { error: err.message };
  }
}

/**
 * Import keyPair from mnemonic, rawSeed or keystore.
 */
function recover(keyType: string, cryptoType: KeypairType, key: string, password: string) {
  return new Promise((resolve, reject) => {
    let keyPair: KeyringPair;
    let mnemonic = "";
    let rawSeed = "";
    try {
      switch (keyType) {
        case "mnemonic":
          if (!mnemonicValidate(key.split("/")[0])) {
            throw new Error(`invalid mnemonic ${key}`);
          }
          keyPair = keyring.addFromMnemonic(key, {}, cryptoType);
          mnemonic = key;
          break;
        case "rawSeed":
          keyPair = keyring.addFromUri(key, {}, cryptoType);
          rawSeed = key;
          break;
        case "keystore":
          const keystore = JSON.parse(key);
          keyPair = keyring.addFromJson(keystore);
          try {
            keyPair.decodePkcs8(password);
          } catch (err) {
            resolve(null);
          }
          resolve({
            pubKey: u8aToHex(keyPair.publicKey),
            ...keyPair.toJson(password),
          });
          break;
      }
    } catch (err) {
      resolve({ error: err.message });
    }
    if (keyPair.address) {
      const json = keyPair.toJson(password);
      keyPair.lock();
      // try add to keyring again to avoid no encrypted data bug
      keyring.addFromJson(json);
      resolve({
        pubKey: u8aToHex(keyPair.publicKey),
        mnemonic,
        rawSeed,
        ...json,
      });
    } else {
      resolve(null);
    }
  });
}

/**
 * Add user's accounts to keyring incedence,
 * so user can use them to sign txs with password.
 * We use a list of ss58Formats to encode the accounts
 * into different address formats for different networks.
 */
async function initKeys(accounts: KeyringPair$Json[], ss58Formats: number[]) {
  await cryptoWaitReady();
  const res = {};
  ss58Formats.forEach((ss58) => {
    (<any>res)[ss58] = {};
  });

  accounts.forEach((i) => {
    // import account to keyring
    const keyPair = keyring.addFromJson(i);
    // then encode address into different ss58 formats
    ss58Formats.forEach((ss58) => {
      const pubKey = u8aToHex(keyPair.publicKey);
      (<any>res)[ss58][pubKey] = keyring.encodeAddress(keyPair.publicKey, ss58);
    });
  });
  return res;
}

/**
 * estimate gas fee of an extrinsic
 */
async function txFeeEstimate(api: ApiPromise, txInfo: any, paramList: any[]) {
  let tx: SubmittableExtrinsic<"promise">;
  // wrap tx with council.propose for treasury propose
  if (txInfo.txName == "treasury.approveProposal") {
    tx = await gov.makeTreasuryProposalSubmission(api, paramList[0], false);
  } else if (txInfo.txName == "treasury.rejectProposal") {
    tx = await gov.makeTreasuryProposalSubmission(api, paramList[0], true);
  } else {
    tx = !!txInfo.txHex ? api.tx(txInfo.txHex) : api.tx[txInfo.module][txInfo.call](...paramList);
  }

  let sender = txInfo.sender.address;
  if (txInfo.proxy) {
    // wrap tx with recovery.asRecovered for proxy tx
    tx = api.tx.recovery.asRecovered(txInfo.sender.address, tx);
    sender = keyring.encodeAddress(hexToU8a(txInfo.proxy.pubKey));
  }
  const dispatchInfo = await tx.paymentInfo(sender);
  return dispatchInfo;
}

function _extractEvents(api: ApiPromise, result: SubmittableResult) {
  if (!result || !result.events) {
    return {};
  }

  let success = false;
  let error: string;
  result.events
    .filter((event) => !!event.event)
    .map(({ event: { data, method, section } }) => {
      if (section === "system" && method === "ExtrinsicFailed") {
        const [dispatchError] = (data as unknown) as ITuple<[DispatchError]>;
        error = _getDispatchError(dispatchError);

        (<any>window).send("txUpdateEvent", {
          title: `${section}.${method}`,
          message: error,
        });
      } else {
        (<any>window).send("txUpdateEvent", {
          title: `${section}.${method}`,
          message: "ok",
        });
        if (section == "system" && method == "ExtrinsicSuccess") {
          success = true;
        }
      }
    });
  return { success, error };
}

export function _getDispatchError(dispatchError: DispatchError): string {
  let message: string = dispatchError.type;

  if (dispatchError.isModule) {
    try {
      const mod = dispatchError.asModule;
      const error = dispatchError.registry.findMetaError(mod);

      message = `${error.section}.${error.name}`;
    } catch (error) {
      // swallow
    }
  } else if (dispatchError.isToken) {
    message = `${dispatchError.type}.${dispatchError.asToken.type}`;
  }

  return message;
}

/**
 * sign and send extrinsic to network and wait for result.
 */
function sendTx(api: ApiPromise, txInfo: any, paramList: any[], password: string, msgId: string) {
  return new Promise(async (resolve) => {
    let tx: SubmittableExtrinsic<"promise">;
    // wrap tx with council.propose for treasury propose
    if (txInfo.txName == "treasury.approveProposal") {
      tx = await gov.makeTreasuryProposalSubmission(api, paramList[0], false);
    } else if (txInfo.txName == "treasury.rejectProposal") {
      tx = await gov.makeTreasuryProposalSubmission(api, paramList[0], true);
    } else {
      tx = !!txInfo.txHex ? api.tx(txInfo.txHex) : api.tx[txInfo.module][txInfo.call](...paramList);
    }
    let unsub = () => {};
    const onStatusChange = (result: SubmittableResult) => {
      if (result.status.isInBlock || result.status.isFinalized) {
        const { success, error } = _extractEvents(api, result);
        if (success) {
          resolve({ hash: tx.hash.toString(), blockHash: (result.status.asInBlock || result.status.asFinalized).toHex() });
        }
        if (error) {
          resolve({ error });
        }
        unsub();
      } else {
        (<any>window).send(msgId, result.status.type);
      }
    };
    if (txInfo.isUnsigned) {
      tx.send(onStatusChange)
        .then((res) => {
          unsub = res;
        })
        .catch((err) => {
          resolve({ error: err.message });
        });
      return;
    }

    let keyPair: KeyringPair;
    if (!txInfo.proxy) {
      keyPair = keyring.getPair(hexToU8a(txInfo.sender.pubKey));
    } else {
      // wrap tx with recovery.asRecovered for proxy tx
      tx = api.tx.recovery.asRecovered(txInfo.sender.address, tx);
      keyPair = keyring.getPair(hexToU8a(txInfo.proxy.pubKey));
    }

    try {
      keyPair.decodePkcs8(password);
    } catch (err) {
      resolve({ error: "password check failed" });
    }
    tx.signAndSend(keyPair, { tip: txInfo.tip }, onStatusChange)
      .then((res) => {
        unsub = res;
      })
      .catch((err) => {
        resolve({ error: err.message });
      });
  });
}

/**
 * check password of an account.
 */
function checkPassword(pubKey: string, pass: string) {
  return new Promise((resolve) => {
    const keyPair = keyring.getPair(hexToU8a(pubKey));
    try {
      if (!keyPair.isLocked) {
        keyPair.lock();
      }
      keyPair.decodePkcs8(pass);
    } catch (err) {
      resolve(null);
    }
    resolve({ success: true });
  });
}

/**
 * change password of an account.
 */
function changePassword(pubKey: string, passOld: string, passNew: string) {
  return new Promise((resolve) => {
    const u8aKey = hexToU8a(pubKey);
    const keyPair = keyring.getPair(u8aKey);
    try {
      if (!keyPair.isLocked) {
        keyPair.lock();
      }
      keyPair.decodePkcs8(passOld);
    } catch (err) {
      resolve(null);
      return;
    }
    const json = keyPair.toJson(passNew);
    keyring.removePair(u8aKey);
    keyring.addFromJson(json);
    resolve({
      pubKey: u8aToHex(keyPair.publicKey),
      ...json,
    });
  });
}

/**
 * check if user input DerivePath valid.
 */
async function checkDerivePath(seed: string, derivePath: string, pairType: KeypairType) {
  try {
    const { path } = keyExtractSuri(`${seed}${derivePath}`);
    // we don't allow soft for ed25519
    if (pairType === "ed25519" && path.some(({ isSoft }) => isSoft)) {
      return "Soft derivation paths are not allowed on ed25519";
    }
  } catch (error) {
    return error.message;
  }
  return null;
}

/**
 * sign tx with QR
 */
async function signAsync(chain: string, password: string) {
  return new Promise((resolve) => {
    const { unsignedData } = getSigner();
    const keyPair = keyring.getPair(unsignedData.data.account);
    try {
      if (!keyPair.isLocked) {
        keyPair.lock();
      }
      keyPair.decodePkcs8(password);

      let payload: any;
      if (!(<any>window).api) {
        const registry = new TypeRegistry();
        registry.setMetadata(new Metadata(registry, metaDataMap[chain]));
        payload = registry.createType("ExtrinsicPayload", unsignedData.data.data, {
          version: 4,
        });
      } else {
        payload = (<any>window).api.registry.createType("ExtrinsicPayload", unsignedData.data.data, {
          version: (<any>window).api.extrinsicVersion,
        });
      }

      const signed = payload.sign(keyPair);
      resolve(signed);
    } catch (err) {
      resolve({ error: err.message });
    }
  });
}

/**
 * send tx with signed data from QR
 */
function addSignatureAndSend(api: ApiPromise, address: string, signed: string) {
  return new Promise((resolve) => {
    const { tx, payload } = getSubmittable();
    if (!!tx.addSignature) {
      tx.addSignature(address, `0x${signed}`, payload);

      let unsub = () => {};
      const onStatusChange = (result: SubmittableResult) => {
        if (result.status.isInBlock || result.status.isFinalized) {
          const { success, error } = _extractEvents(api, result);
          if (success) {
            resolve({ hash: tx.hash.toString(), blockHash: (result.status.asInBlock || result.status.asFinalized).toHex() });
          }
          if (error) {
            resolve({ error });
          }
          unsub();
        } else {
          (<any>window).send("txStatusChange", result.status.type);
        }
      };

      tx.send(onStatusChange)
        .then((res) => {
          unsub = res;
        })
        .catch((err) => {
          resolve({ error: err.message });
        });
    } else {
      resolve({ error: "invalid tx" });
    }
  });
}

/**
 * sign tx from dapp as extension
 */
async function signTxAsExtension(password: string, json: any) {
  return new Promise((resolve) => {
    const keyPair = keyring.getPair(json["address"]);
    try {
      if (!keyPair.isLocked) {
        keyPair.lock();
      }
      keyPair.decodePkcs8(password);

      let registry: any;
      if (!(<any>window).api) {
        registry = new TypeRegistry();
        registry.setMetadata(new Metadata(registry, metaDataMap["kusama"] as any));
      } else {
        registry = (<any>window).api.registry;
      }

      registry.setSignedExtensions(json["signedExtensions"]);
      const payload = registry.createType("ExtrinsicPayload", json, {
        version: json["version"],
      });
      const signed = payload.sign(keyPair);
      resolve(signed);
    } catch (err) {
      resolve({ error: err.message });
    }
  });
}

/**
 * sign bytes from dapp as extension
 */
async function signBytesAsExtension(password: string, json: any) {
  return new Promise((resolve) => {
    const keyPair = keyring.getPair(json["address"]);
    try {
      if (!keyPair.isLocked) {
        keyPair.lock();
      }
      keyPair.decodePkcs8(password);
      resolve({
        signature: u8aToHex(keyPair.sign(unwrapBytes(json["data"]))),
      });
    } catch (err) {
      resolve({ error: err.message });
    }
  });
}

async function verifySignature(message: string, signature: string, address: string) {
  return signatureVerify(wrapBytes(message), signature, address);
}

export default {
  initKeys,
  gen,
  checkMnemonicValid,
  addressFromMnemonic,
  addressFromRawSeed,
  recover,
  txFeeEstimate,
  sendTx,
  checkPassword,
  changePassword,
  checkDerivePath,
  parseQrCode,
  signAsync,
  makeTx,
  addSignatureAndSend,
  signTxAsExtension,
  signBytesAsExtension,
  verifySignature,
};

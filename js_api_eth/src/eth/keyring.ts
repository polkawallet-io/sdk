import { ethers } from "ethers";
import { verifyMessage } from "@ethersproject/wallet";
import Jazzicon from "@metamask/jazzicon";

/**
 * Generate a set of new mnemonic.
 * svg code from https://github.com/smart-dev817/uniswap-interface/blob/1cc5ceec4dbe29cad3378eb321fdc88e3eb79304/src/components/Identicon/index.tsx#L15
 */
async function gen(mnemonic: string, index: number) {
  const derivePath = ethers.utils.defaultPath.split("/");
  const path = derivePath.slice(0, derivePath.length - 1).join("/") + "/" + (index || 0).toString();
  const wallet = !!mnemonic ? ethers.Wallet.fromMnemonic(mnemonic, path) : ethers.Wallet.createRandom({ path });
  const icon = Jazzicon(16, parseInt(wallet.address.slice(2, 10), 16));
  return {
    mnemonic: wallet.mnemonic.phrase,
    path: wallet.mnemonic.path,
    address: wallet.address,
    svg: icon.innerHTML,
  };
}

/**
 * get address and avatar from mnemonic.
 */
async function addressFromMnemonic(mnemonic: string, derivePath: string) {
  try {
    const wallet = ethers.Wallet.fromMnemonic(mnemonic, derivePath);
    const icon = Jazzicon(16, parseInt(wallet.address.slice(2, 10), 16));
    return {
      address: wallet.address,
      svg: icon.innerHTML,
    };
  } catch (err) {
    return { error: err.message };
  }
}

/**
 * get address and avatar from privateKey.
 */
async function addressFromPrivateKey(privateKey: string) {
  try {
    const wallet = new ethers.Wallet(privateKey);
    const icon = Jazzicon(16, parseInt(wallet.address.slice(2, 10), 16));
    return {
      address: wallet.address,
      svg: icon.innerHTML,
    };
  } catch (err) {
    return { error: err.message };
  }
}

/**
 * Import keyPair from mnemonic, privateKey or keystore.
 */
async function recover(keyType: string, key: string, derivePath: string, password: string) {
  let keyPair: ethers.Wallet;
  let mnemonic = "";
  let privateKey = "";
  try {
    switch (keyType) {
      case "mnemonic":
        keyPair = ethers.Wallet.fromMnemonic(key, derivePath);
        mnemonic = key;
        break;
      case "privateKey":
        keyPair = new ethers.Wallet(key);
        privateKey = key;
        break;
      case "keystore":
        keyPair = await ethers.Wallet.fromEncryptedJson(key, password);
        break;
    }
  } catch (err) {
    return { error: err.message };
  }
  if (keyPair.address) {
    const res = await keyPair.encrypt(password);
    return {
      pubKey: keyPair.publicKey,
      address: keyPair.address,
      mnemonic,
      privateKey,
      keystore: res,
    };
  }
  return null;
}

/**
 * check password of an account.
 */
async function checkPassword(keystore: string, pass: string) {
  try {
    const wallet = await ethers.Wallet.fromEncryptedJson(keystore, pass);
    return { success: !!wallet.address };
  } catch (err) {
    return { success: false, error: err.message };
  }
}

/**
 * change password of an account.
 */
async function changePassword(keystore: string, passOld: string, passNew: string) {
  try {
    const keyPair = await ethers.Wallet.fromEncryptedJson(keystore, passOld);
    if (keyPair.address) {
      const res = await keyPair.encrypt(passNew);
      return {
        pubKey: keyPair.publicKey,
        address: keyPair.address,
        keystore: res,
      };
    }
  } catch (err) {
    return { success: false, error: err.message };
  }
}

/**
 * sign message with private key of an account.
 */
async function signMessage(message: string, keystore: string, pass: string) {
  try {
    const keyPair = await ethers.Wallet.fromEncryptedJson(keystore, pass);
    if (keyPair.address) {
      const res = await keyPair.signMessage(message);
      return {
        pubKey: keyPair.publicKey,
        address: keyPair.address,
        signature: res,
      };
    }
  } catch (err) {
    return { success: false, error: err.message };
  }
}

/**
 * get signer of a signature. so we can verify the signer.
 */
async function verifySignature(message: string, signature: string) {
  try {
    const res = verifyMessage(message, signature);
    return { signer: res };
  } catch (err) {
    return { error: err.message };
  }
}

export default { gen, addressFromMnemonic, addressFromPrivateKey, recover, checkPassword, changePassword, signMessage, verifySignature };

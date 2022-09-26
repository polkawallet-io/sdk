import { ethers } from "ethers";
import { verifyMessage } from "@ethersproject/wallet";
import accountETH from "./account";
import { erc20Abi, getProvider } from "./settings";
import { signTypedData_v4, recoverTypedSignature_v4 } from "eth-sig-util";

interface GasOptions {
  gasLimit: number;
  gasPrice: string;
  maxFeePerGas: string;
  maxPriorityFeePerGas: string;
}

interface WCRequest {
  request: {
    method: string;
    params: any;
  };
  chainId: string;
}

/// use this Map to store user's accounts
const keystoreMap: Record<string, string> = {};

function _formatAddress(address: string) {
  return address.startsWith('0x') ? address : `0x${address}`;
}
function _updateAccount(address: string, keystore: string) {
  keystoreMap[_formatAddress(address.toLowerCase())] = keystore;
}
function _findAccount(address: string) {
  return keystoreMap[_formatAddress(address.toLowerCase())];
}

async function initKeys(accounts: any[]) {
  accounts.forEach(e => {
    _updateAccount(e['address'], JSON.stringify(e));
  });
}

/**
 * Generate a set of new mnemonic.
 * svg code from https://github.com/smart-dev817/uniswap-interface/blob/1cc5ceec4dbe29cad3378eb321fdc88e3eb79304/src/components/Identicon/index.tsx#L15
 */
async function gen(mnemonic: string, index: number) {
  const derivePath = ethers.utils.defaultPath.split("/");
  const path = derivePath.slice(0, derivePath.length - 1).join("/") + "/" + (index || 0).toString();
  const wallet = !!mnemonic ? ethers.Wallet.fromMnemonic(mnemonic, path) : ethers.Wallet.createRandom({ path });
  const icon = (await accountETH.genIcons([wallet.address]))[0];
  return {
    mnemonic: wallet.mnemonic.phrase,
    path: wallet.mnemonic.path,
    address: wallet.address,
    svg: icon[1],
  };
}

/**
 * get address and avatar from mnemonic.
 */
async function addressFromMnemonic(mnemonic: string, derivePath: string) {
  try {
    const wallet = ethers.Wallet.fromMnemonic(mnemonic, derivePath);
    const icon = (await accountETH.genIcons([wallet.address]))[0];
    return {
      address: wallet.address,
      svg: icon[1],
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
    const icon = (await accountETH.genIcons([wallet.address]))[0];
    return {
      address: wallet.address,
      svg: icon[1],
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
    const res = await keyPair.encrypt(password, { scrypt: { N: 1 << 14 } });
    _updateAccount(keyPair.address, res);
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
async function checkPassword(address: string, pass: string) {
  const keystore = _findAccount(address);
  if (!keystore) return { success: false, error: `Can not find account ${address}` };

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
async function changePassword(address: string, passOld: string, passNew: string) {
  const keystore = _findAccount(address);
  if (!keystore) return { success: false, error: `Can not find account ${address}` };

  try {
    const keyPair = await ethers.Wallet.fromEncryptedJson(keystore, passOld);
    if (keyPair.address) {
      const res = await keyPair.encrypt(passNew, { scrypt: { N: 1 << 14 } });
      _updateAccount(keyPair.address, res);
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
async function signMessage(message: string, address: string, pass: string) {
  const keystore = _findAccount(address);
  if (!keystore) return { success: false, error: `Can not find account ${address}` };

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

/**
 * sign typedData with private key of an account.
 */
async function signTypedData(data: any, address: string, pass: string) {
  const keystore = _findAccount(address);
  if (!keystore) return { success: false, error: `Can not find account ${address}` };

  try {
    const keyPair = await ethers.Wallet.fromEncryptedJson(keystore, pass);
    if (keyPair.address) {
      const res = signTypedData_v4(Buffer.from(keyPair.privateKey.slice(2), "hex"), {
        data: data,
      });
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
async function verifyTypedData(data: any, signature: string) {
  try {
    const res = recoverTypedSignature_v4({ data: data, sig: signature });
    return { signer: res };
  } catch (err) {
    return { error: err.message };
  }
}

async function estimateTransferGas(token: string, amount: number, to: string) {
  if (token.startsWith('0x')) {
    const contract = new ethers.Contract(token, erc20Abi, getProvider());
    const decimals = await contract.decimals();
    const gas = await contract.estimateGas.transfer(to, ethers.utils.parseUnits(amount.toString(), decimals));
    return gas.toNumber();
  } else {
    const gas = await getProvider().estimateGas({
      to,
      value: ethers.utils.parseEther(amount.toString()),
    });
    return gas.toNumber();
  }
}

async function getGasPrice() {
  const gasPrice = await getProvider().getGasPrice();
  return gasPrice.toString();
}

async function transfer(token: string, amount: number, to: string, sender: string, pass: string, gasOptions: GasOptions) {
  const keystore = _findAccount(sender);
  if (!keystore) return { success: false, error: `Can not find account ${sender}` };

  try {
    const keyPair = await ethers.Wallet.fromEncryptedJson(keystore, pass);
    if (keyPair.address) {
      const signer = keyPair.connect(getProvider());
      const options = {
        maxFeePerGas: ethers.utils.parseUnits(gasOptions.maxFeePerGas, 9),
        maxPriorityFeePerGas: ethers.utils.parseUnits(gasOptions.maxPriorityFeePerGas, 9),
      };
      let res: ethers.providers.TransactionResponse;
      if (token === "ETH") {
        res = await signer.sendTransaction({
          to,
          value: ethers.utils.parseEther(amount.toString()),
          gasLimit: ethers.utils.parseUnits("21", 3),
          ...options,
        });
      } else {
        const contract = new ethers.Contract(token, erc20Abi, signer);
        const decimals = await contract.decimals();
        res = await contract.transfer(to, ethers.utils.parseUnits(amount.toString(), decimals), {
          ...options,
          gasLimit: ethers.utils.parseUnits("200", 3),
        });
      }
      return {
        pubKey: keyPair.publicKey,
        address: keyPair.address,
        hash: res.hash,
      };
    }
  } catch (err) {
    return { success: false, error: err.message };
  }
}

async function signAndSendTx(tx: ethers.providers.TransactionRequest, sender: string, pass: string, gasOptions: GasOptions) {
  const keystore = _findAccount(sender);
  if (!keystore) return { success: false, error: `Can not find account ${sender}` };

  try {
    const keyPair = await ethers.Wallet.fromEncryptedJson(keystore, pass);
    if (keyPair.address) {
      const signer = keyPair.connect(getProvider());
      const res = await signer.sendTransaction({
        ...tx,
        maxFeePerGas: ethers.utils.parseUnits(gasOptions.maxFeePerGas, 9),
        maxPriorityFeePerGas: ethers.utils.parseUnits(gasOptions.maxPriorityFeePerGas, 9),
      });
      return {
        pubKey: keyPair.publicKey,
        address: keyPair.address,
        hash: res.hash,
      };
    }
  } catch (err) {
    return { success: false, error: err.message };
  }
}

export default {
  initKeys,
  gen,
  addressFromMnemonic,
  addressFromPrivateKey,
  recover,
  checkPassword,
  changePassword,
  signMessage,
  verifySignature,
  estimateTransferGas,
  getGasPrice,
  transfer,
  signAndSendTx,
  signTypedData,
  verifyTypedData,
};

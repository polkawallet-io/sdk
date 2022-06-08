import { ethers } from "ethers";
import { verifyMessage } from "@ethersproject/wallet";
import Jazzicon from "@metamask/jazzicon";
import { erc20Abi, getProvider } from "./settings";

interface GasOptions {
  maxFeePerGas: string;
  maxPriorityFeePerGas: string;
}

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
    const res = await keyPair.encrypt(password, { scrypt: { N: 1 << 14 } });
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
async function checkPassword(keystore: object, pass: string) {
  try {
    const wallet = await ethers.Wallet.fromEncryptedJson(JSON.stringify(keystore), pass);
    return { success: !!wallet.address };
  } catch (err) {
    return { success: false, error: err.message };
  }
}

/**
 * change password of an account.
 */
async function changePassword(keystore: object, passOld: string, passNew: string) {
  try {
    const keyPair = await ethers.Wallet.fromEncryptedJson(JSON.stringify(keystore), passOld);
    if (keyPair.address) {
      const res = await keyPair.encrypt(passNew, { scrypt: { N: 1 << 14 } });
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
async function signMessage(message: string, keystore: object, pass: string) {
  try {
    const keyPair = await ethers.Wallet.fromEncryptedJson(JSON.stringify(keystore), pass);
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

// async function estimateTransferGas(token: string, amount: number, to: string) {
//   try {
//     if (token === "ETH") {
//       const gas = await getProvider().estimateGas({
//         to,
//         value: ethers.utils.parseEther(amount.toString()),
//       });
//       return gas.toString();
//     } else {
//       const contract = new ethers.Contract(token, erc20Abi, getProvider());
//       const decimals = await contract.decimals();
//       const gas = await contract.estimateGas.transfer(to, ethers.utils.parseUnits(amount.toString(), decimals));
//       return gas.toString();
//     }
//   } catch (err) {
//     return { success: false, error: err.message };
//   }
// }

async function transfer(token: string, amount: number, to: string, keystore: object, pass: string, gasOptions: GasOptions) {
  try {
    const keyPair = await ethers.Wallet.fromEncryptedJson(JSON.stringify(keystore), pass);
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

async function signAndSendTx(tx: ethers.providers.TransactionRequest, keystore: object, pass: string, gasOptions: GasOptions) {
  try {
    const keyPair = await ethers.Wallet.fromEncryptedJson(JSON.stringify(keystore), pass);
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
  gen,
  addressFromMnemonic,
  addressFromPrivateKey,
  recover,
  checkPassword,
  changePassword,
  signMessage,
  verifySignature,
  // estimateTransferGas,
  transfer,
  signAndSendTx,
};

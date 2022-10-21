import Jazzicon from "@metamask/jazzicon";
import { erc20Abi, getWeb3 } from "./settings";
/**
 * Get svg icons of addresses.
 */
async function genIcons(addresses: string[]) {
  return addresses.map((address) => {
    const icon = Jazzicon(16, parseInt(address.slice(2, 10), 16));
    return [address, icon.innerHTML.replace(">", `><rect x="0" y="0" width="16" height="16" fill="${icon.style.background}"></rect>`)];
  });
}

async function getEthBalance(address: string) {
  return getWeb3().eth.getBalance(address);
}

async function getTokenBalance(address: string, contractAddresses: string[]) {
  return Promise.all(
    contractAddresses.map(async (token) => {
      const web3 = getWeb3().eth;
      const contract = new web3.Contract(erc20Abi, token);
      const [symbol, name, decimals, balance] = await Promise.all([
        contract.methods.symbol().call(),
        contract.methods.name().call(),
        contract.methods.decimals().call(),
        contract.methods.balanceOf(address).call(),
      ]);
      return {
        contractAddress: token,
        symbol,
        name,
        decimals,
        amount: balance.toString(),
      };
    })
  );
}

/**
 * validate input address & return checksumed.
 */
async function getAddress(address: string) {
  return getWeb3().utils.toChecksumAddress(address);
}

export default {
  genIcons,
  getEthBalance,
  getTokenBalance,
  getAddress,
};

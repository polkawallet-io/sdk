import Jazzicon from "@metamask/jazzicon";
import { ethers } from "ethers";
import { erc20Abi, getProvider } from "./settings";
/**
 * Get svg icons of addresses.
 */
async function genIcons(addresses: string[]) {
  return addresses.map((address) => {
    const icon = Jazzicon(16, parseInt(address.slice(2, 10), 16));
    return [address, icon.innerHTML.replace('>', ` style="background-color:${icon.style.background}">`)];
  });
}

async function getEthBalance(address: string) {
  const res = await getProvider().getBalance(address);
  return {
    amount: res.toString(),
    decimals: 18,
  };
}

async function getTokenBalance(address: string, contractAddresses: string[]) {
  return Promise.all(
    contractAddresses.map(async (token) => {
      const contract = new ethers.Contract(token, erc20Abi, getProvider());
      const [symbol, name, decimals, balance] = await Promise.all([
        contract.symbol(),
        contract.name(),
        contract.decimals(),
        contract.balanceOf(address),
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

export default {
  genIcons,
  getEthBalance,
  getTokenBalance,
};

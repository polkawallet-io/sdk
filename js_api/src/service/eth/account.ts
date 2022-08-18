import Jazzicon from "@metamask/jazzicon";
import { ethers } from "ethers";
import { erc20Abi, getProvider } from "./settings";
/**
 * Get svg icons of addresses.
 */
async function genIcons(addresses: string[]) {
  return addresses.map((address) => {
    const icon = Jazzicon(16, parseInt(address.slice(2, 10), 16));
    return [address, icon.innerHTML.replace('>', `><rect x="0" y="0" width="16" height="16" fill="${icon.style.background}"></rect>`)];
  });
}

async function getEthBalance(address: string) {
  const res = await getProvider().getBalance(address);
  return res.toString();
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

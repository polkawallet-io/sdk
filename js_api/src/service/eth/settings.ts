import { ethers } from "ethers";

let provider: ethers.providers.JsonRpcProvider;

export const erc20Abi = [
  // Some details about the token
  "function name() view returns (string)",
  "function symbol() view returns (string)",
  "function decimals() view returns (uint8)",

  // Get the account balance
  "function balanceOf(address) view returns (uint)",

  // Send some of your tokens to someone else
  "function transfer(address to, uint amount)",

  // An event triggered whenever anyone transfers to someone else
  "event Transfer(address indexed from, address indexed to, uint amount)",
];

export async function connect(url: string) {
  provider = new ethers.providers.JsonRpcProvider(url);
  return await provider.ready;
}

export function getProvider() {
  return provider;
}

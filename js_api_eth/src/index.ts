// ethers APIs:
import keyringETH from "./eth/keyring";
import accountETH from "./eth/account";
import { connect } from "./eth/settings";

(window as any).send = function(path: string, data: any) {
  console.log(JSON.stringify({ path, data }));
};

(window as any).send("log", "eth main js loaded");

(window as any).eth = { settings: { connect }, keyring: keyringETH, account: accountETH };

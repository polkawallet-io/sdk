import { cryptoWaitReady } from "@polkadot/util-crypto";
import { hexToU8a, u8aToHex, hexToString } from "@polkadot/util";
// @ts-ignore
import { ss58Decode } from "oo7-substrate/src/ss58";
import { polkadotIcon } from "@polkadot/ui-shared";

import { Keyring } from "@polkadot/keyring";
import { ApiPromise } from "@polkadot/api";

import { subscribeMessage } from "./setting";
let keyring = new Keyring({ ss58Format: 0, type: "sr25519" });

/**
 * Get svg icons of addresses.
 */
async function genIcons(addresses: string[]) {
  return addresses.map((i) => {
    const circles = polkadotIcon(i, { isAlternative: false })
      .map(
        ({ cx, cy, fill, r }) =>
          `<circle cx='${cx}' cy='${cy}' fill='${fill}' r='${r}' />`
      )
      .join("");
    return [
      i,
      `<svg viewBox='0 0 64 64' xmlns='http://www.w3.org/2000/svg'>${circles}</svg>`,
    ];
  });
}

/**
 * Get svg icons of pubKeys.
 */
async function genPubKeyIcons(pubKeys: string[]) {
  const icons = await genIcons(
    pubKeys.map((key) => keyring.encodeAddress(hexToU8a(key), 2))
  );
  return icons.map((i, index) => {
    i[0] = pubKeys[index];
    return i;
  });
}

/**
 * decode address to it's publicKey
 */
async function decodeAddress(addresses: string[]) {
  await cryptoWaitReady();
  try {
    const res = {};
    addresses.forEach((i) => {
      const pubKey = u8aToHex(keyring.decodeAddress(i));
      (<any>res)[pubKey] = i;
    });
    return res;
  } catch (err) {
    (<any>window).send("log", { error: err.message });
    return null;
  }
}

/**
 * encode pubKey to addresses with different prefixes
 */
async function encodeAddress(pubKeys: string[], ss58Formats: number[]) {
  await cryptoWaitReady();
  const res = {};
  ss58Formats.forEach((ss58) => {
    (<any>res)[ss58] = {};
    pubKeys.forEach((i) => {
      (<any>res)[ss58][i] = keyring.encodeAddress(hexToU8a(i), ss58);
    });
  });
  return res;
}

/**
 * query account address with account index
 */
async function queryAddressWithAccountIndex(
  api: ApiPromise,
  accIndex: string,
  ss58: number
) {
  const num = ss58Decode(accIndex, ss58).toJSON();
  const res = await api.query.indices.accounts(num.data);
  return res;
}

/**
 * get staking stash/controller relationship of accounts
 */
async function queryAccountsBonded(api: ApiPromise, pubKeys: string[]) {
  return Promise.all(
    pubKeys
      .map((key) => keyring.encodeAddress(hexToU8a(key), 2))
      .map((i) =>
        Promise.all([api.query.staking.bonded(i), api.query.staking.ledger(i)])
      )
  ).then((ls) =>
    ls.map((i, index) => [
      pubKeys[index],
      i[0],
      i[1].toHuman() ? i[1].toHuman()["stash"] : null,
    ])
  );
}

/**
 * get network native token balance of an address
 */
async function getBalance(
  api: ApiPromise,
  address: string,
  msgChannel: string
) {
  const transfrom = (res: any) => {
    const lockedBreakdown = res.lockedBreakdown.map((i: any) => {
      return {
        ...i,
        use: hexToString(i.id.toHex()),
      };
    });
    return {
      ...res,
      lockedBreakdown,
    };
  };
  if (msgChannel) {
    subscribeMessage(api.derive.balances.all, [address], msgChannel, transfrom);
    return;
  }

  const res = await api.derive.balances.all(address);
  return transfrom(res);
}

/**
 * get humen info of addresses
 */
async function getAccountIndex(api: ApiPromise, addresses: string[]) {
  return api.derive.accounts.indexes().then((res) => {
    return Promise.all(addresses.map((i) => api.derive.accounts.info(i)));
  });
}

export default {
  encodeAddress,
  decodeAddress,
  queryAddressWithAccountIndex,
  genIcons,
  genPubKeyIcons,
  queryAccountsBonded,
  getBalance,
  getAccountIndex,
};

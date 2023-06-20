import { ApiPromise } from "@polkadot/api";
import { SubstrateNetworkKeys } from "../constants/networkSpect";

const MAX_NOMINATIONS = 16;

/**
 * subscribe messages of network state.
 *
 * @param {Function} method i.e. api.derive.chain.bestNumber
 * @param {List<String>} params
 * @param {String} msgChannel
 * @param {Function} transfrom result data transfrom
 */
export async function subscribeMessage(method: any, params: any[], msgChannel: string, transfrom: Function) {
  return method(...params, (res: any) => {
    const data = transfrom ? transfrom(res) : res;
    (<any>window).send(msgChannel, data);
  }).then((unsub: () => void) => {
    const unsubFuncName = `unsub${msgChannel}`;
    (<any>window)[unsubFuncName] = unsub;
    return {};
  });
}

/**
 * get consts of network.
 */
export async function getNetworkConst(api: ApiPromise) {
  return {
    auctions: {
      endingPeriod: api.consts.auctions?.endingPeriod,
    },
    babe: {
      expectedBlockTime: api.consts.babe?.expectedBlockTime,
    },
    balances: {
      existentialDeposit: api.consts.balances?.existentialDeposit,
    },
    staking: {
      maxNominations: api.consts.staking?.maxNominations || MAX_NOMINATIONS,
      maxNominatorRewardedPerValidator: api.consts.staking?.maxNominatorRewardedPerValidator,
    },
    timestamp: {
      minimumPeriod: api.consts.timestamp?.minimumPeriod,
    },
    treasury: {
      proposalBondMinimum: api.consts.treasury?.proposalBondMinimum,
      proposalBond: api.consts.treasury?.proposalBond,
      spendPeriod: api.consts.treasury?.spendPeriod,
    },
  };
}

/**
 * get network properties, and replace polkadot decimals with const 10.
 */
export async function getNetworkProperties(api: ApiPromise) {
  const chainProperties = await api.rpc.system.properties();
  const genesisHash = api.genesisHash.toHuman();
  return genesisHash == SubstrateNetworkKeys.POLKADOT
    ? api.registry.createType("ChainProperties", {
        ...chainProperties.toJSON(),
        tokenDecimals: [10],
        tokenSymbol: ["DOT"],
        genesisHash,
      })
    : { ...chainProperties.toJSON(), genesisHash };
}

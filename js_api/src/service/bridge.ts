import { ApiProvider, BalanceData, Bridge, chains, FN, RegisteredChainName } from "@polkawallet/bridge";
import { KusamaAdapter } from "@polkawallet/bridge/build/adapters/polkadot";
import { KaruraAdapter } from "@polkawallet/bridge/build/adapters/acala";
import { Observable, firstValueFrom, combineLatest } from "rxjs";
import { BaseCrossChainAdapter } from "@polkawallet/bridge/build/base-chain-adapter";
import { subscribeMessage } from "./setting";

const provider = new ApiProvider();

const availableAdapters: Record<string, BaseCrossChainAdapter> = {
  kusama: new KusamaAdapter(),
  karura: new KaruraAdapter(),
};
const bridge = new Bridge({
  adapters: Object.values(availableAdapters),
});

async function connectFromChains() {
  const fromChains = Object.keys(availableAdapters) as RegisteredChainName[];
  // connect all adapters
  const connected = await firstValueFrom(provider.connectFromChain(fromChains));

  await Promise.all(fromChains.map((chain) => availableAdapters[chain].setApi(provider.getApi(chain))));
  return connected;
}

async function disconnectFromChains() {
  const fromChains = Object.keys(availableAdapters) as RegisteredChainName[];
  fromChains.forEach((e) => provider.disconnect(e));
}

async function getFromChainsAll() {
  return Object.keys(availableAdapters);
}

async function getRoutes() {
  return bridge.getRouters().map((e) => ({ from: e.from.id, to: e.to.id, token: e.token }));
}

async function getChainsInfo() {
  return chains;
}

async function getAvailableTokens(from: RegisteredChainName, to: RegisteredChainName) {
  return bridge.getAvailableTokens({ from, to });
}

async function getFromChains(token: string, to: RegisteredChainName) {
  return bridge.getFromChains({ token, to });
}

async function getToChains(token: string, from: RegisteredChainName) {
  return bridge.getDestiantionsChains({ token, from });
}

async function subscribeBalancesInner(chain: RegisteredChainName, address: string, callback: Function) {
  const adapter = bridge.findAdapterByName(chain);
  const tokens = {};
  adapter.getRouters().forEach((e) => {
    tokens[e.token] = true;
  });
  const sub = combineLatest(
    Object.keys(tokens).reduce((res, token) => {
      return { ...res, [token]: adapter.subscribeTokenBalance(token, address) };
    }, {}) as Record<string, Observable<BalanceData>>
  ).subscribe((all) => {
    callback(
      Object.keys(all).reduce(
        (res, token) => ({
          ...res,
          [token]: {
            token,
            decimals: all[token].free.getPrecision(),
            free: all[token].free.toChainData().toString(),
            locked: all[token].locked.toChainData().toString(),
            reserved: all[token].reserved.toChainData().toString(),
            available: all[token].available.toChainData().toString(),
          },
        }),
        {}
      )
    );
  });
  return () => sub.unsubscribe();
}

async function subscribeBalances(chain: RegisteredChainName, address: string, msgChannel: string) {
  subscribeMessage((<any>window).bridge.subscribeBalancesInner, [chain, address], msgChannel, undefined);
  return;
}

async function getInputConfig(from: RegisteredChainName, to: RegisteredChainName, token: string, address: string) {
  const adapter = bridge.findAdapterByName(from);

  const res = await firstValueFrom(adapter.subscribeInputConfigs({ to, token, address }));
  return {
    from,
    to,
    token,
    address,
    decimals: res.minInput.getPrecision(),
    minInput: res.minInput.toChainData().toString(),
    maxInput: res.maxInput.toChainData().toString(),
  };
}

async function getTxParams(
  chainFrom: RegisteredChainName,
  chainTo: RegisteredChainName,
  token: string,
  address: string,
  amount: string,
  decimals: number
) {
  const adapter = bridge.findAdapterByName(chainFrom);
  return adapter.getBridgeTxParams({ to: chainTo, token, address, amount: FN.fromInner(amount, decimals) });
}

export default {
  getFromChainsAll,
  getRoutes,
  getChainsInfo,
  connectFromChains,
  disconnectFromChains,
  getAvailableTokens,
  getFromChains,
  getToChains,
  subscribeBalancesInner,
  subscribeBalances,
  getInputConfig,
  getTxParams,
};

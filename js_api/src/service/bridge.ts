import { ApiProvider, BalanceData, Bridge, chains, FN, RegisteredChainName } from "@polkawallet/bridge";
import { KusamaAdapter } from "@polkawallet/bridge/build/adapters/polkadot";
import { KaruraAdapter } from "@polkawallet/bridge/build/adapters/acala";
import { Observable, firstValueFrom, combineLatest } from "rxjs";
import { BaseCrossChainAdapter } from "@polkawallet/bridge/build/base-chain-adapter";
import { subscribeMessage } from "./setting";

const provider = new ApiProvider();

const availableAdapters: Record<string, BaseCrossChainAdapter> = {
  karura: new KaruraAdapter(),
  kusama: new KusamaAdapter(),
};
const bridge = new Bridge({
  adapters: Object.values(availableAdapters),
});

async function connectFromChains(chains: RegisteredChainName[], nodeList: Partial<Record<RegisteredChainName, string[]>> | undefined) {
  // connect all adapters
  const connected = await firstValueFrom(provider.connectFromChain(chains, nodeList));

  await Promise.all(chains.map((chain) => availableAdapters[chain].setApi(provider.getApi(chain))));
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
  return bridge.router.getRouters().map((e) => ({ from: e.from.id, to: e.to.id, token: e.token }));
}

async function getChainsInfo() {
  return chains;
}

async function getNetworkProperties(chain: RegisteredChainName) {
  return bridge.findAdapter(chain).getNetworkProperties();
}

async function subscribeBalancesInner(chain: RegisteredChainName, address: string, callback: Function) {
  const adapter = bridge.findAdapter(chain);
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
  const adapter = bridge.findAdapter(from);

  const res = await firstValueFrom(adapter.subscribeInputConfigs({ to, token, address }));
  return {
    from,
    to,
    token,
    address,
    decimals: res.minInput.getPrecision(),
    minInput: res.minInput.toChainData().toString(),
    maxInput: res.maxInput.toChainData().toString(),
    destFee: res.destFee,
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
  const adapter = bridge.findAdapter(chainFrom);
  return adapter.getBridgeTxParams({ to: chainTo, token, address, amount: FN.fromInner(amount, decimals) });
}

async function getApi(chainName: RegisteredChainName) {
  return provider.getApiPromise(chainName);
}

export default {
  getFromChainsAll,
  getRoutes,
  getChainsInfo,
  connectFromChains,
  disconnectFromChains,
  getNetworkProperties,
  subscribeBalancesInner,
  subscribeBalances,
  getInputConfig,
  getTxParams,
  getApi,
};

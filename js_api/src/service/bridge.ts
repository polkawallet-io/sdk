import { ApiProvider, BalanceData, Bridge, chains, FN, ChainId } from "@polkawallet/bridge";
import { KusamaAdapter, PolkadotAdapter } from "@polkawallet/bridge/adapters/polkadot";
import { AcalaAdapter, KaruraAdapter } from "@polkawallet/bridge/adapters/acala";
import { StatemineAdapter } from "@polkawallet/bridge/adapters/statemint";
import { AltairAdapter } from "@polkawallet/bridge/adapters/centrifuge";
import { AstarAdapter, ShidenAdapter } from "@polkawallet/bridge/adapters/astar";
import { BifrostAdapter } from "@polkawallet/bridge/adapters/bifrost";
import { CalamariAdapter } from "@polkawallet/bridge/adapters/manta";
import { ShadowAdapter } from "@polkawallet/bridge/adapters/crust";
import { CrabAdapter } from "@polkawallet/bridge/adapters/darwinia";
import { IntegriteeAdapter } from "@polkawallet/bridge/adapters/integritee";
import { QuartzAdapter, UniqueAdapter } from "@polkawallet/bridge/adapters/unique";
import { KintsugiAdapter, InterlayAdapter } from "@polkawallet/bridge/adapters/interlay";
import { TuringAdapter } from "@polkawallet/bridge/adapters/oak";
import { ParallelAdapter, HeikoAdapter } from "@polkawallet/bridge/adapters/parallel";
import { KhalaAdapter } from "@polkawallet/bridge/adapters/phala";
import { BasiliskAdapter, HydraDxAdapter } from "@polkawallet/bridge/adapters/hydradx";
import { MoonbeamAdapter, MoonriverAdapter } from "@polkawallet/bridge/adapters/moonbeam";
import { Observable, firstValueFrom, combineLatest } from "rxjs";
import { BaseCrossChainAdapter } from "@polkawallet/bridge/base-chain-adapter";
import { subscribeMessage } from "./setting";

import { Keyring } from "@polkadot/keyring";
import { KeyringPair$Json } from "@polkadot/keyring/types";
import { cryptoWaitReady } from "@polkadot/util-crypto";

import { BN } from "@polkadot/util";
import { ITuple } from "@polkadot/types/types";
import { DispatchError } from "@polkadot/types/interfaces";
import { SubmittableResult } from "@polkadot/api/submittable";

import { EvmRpcProvider } from "@acala-network/eth-providers";
import { Wallet } from "@acala-network/sdk/wallet";

let keyring = new Keyring({ ss58Format: 0, type: "sr25519" });

const provider = new ApiProvider();

const availableAdapters: Record<string, BaseCrossChainAdapter> = {
  polkadot: new PolkadotAdapter(),
  kusama: new KusamaAdapter(),
  acala: new AcalaAdapter(),
  karura: new KaruraAdapter(),
  altair: new AltairAdapter(),
  astar: new AstarAdapter(),
  basilisk: new BasiliskAdapter(),
  bifrost: new BifrostAdapter(),
  calamari: new CalamariAdapter(),
  crab: new CrabAdapter(),
  heiko: new HeikoAdapter(),
  hydradx: new HydraDxAdapter(),
  integritee: new IntegriteeAdapter(),
  interlay: new InterlayAdapter(),
  khala: new KhalaAdapter(),
  kintsugi: new KintsugiAdapter(),
  // kico: new KicoAdapter(),
  // listen: new ListenAdapter(),
  moonbeam: new MoonbeamAdapter(),
  moonriver: new MoonriverAdapter(),
  parallel: new ParallelAdapter(),
  // pichiu: new PichiuAdapter(),
  quartz: new QuartzAdapter(),
  shadow: new ShadowAdapter(),
  shiden: new ShidenAdapter(),
  statemine: new StatemineAdapter(),
  turing: new TuringAdapter(),
  unique: new UniqueAdapter(),
};
let bridge: Bridge;

const _initBridge = async () => {
  if (!bridge) {
    bridge = new Bridge({
      adapters: Object.values(availableAdapters),
      disabledRouters: "https://acala.polkawallet-cloud.com/config/bridge.json",
    });

    await bridge.isReady;
  }
};

async function connectFromChains(chains: ChainId[], nodeList: Partial<Record<ChainId, string[]>> | undefined) {
  nodeList = {
    acala: ["wss://acala-rpc.dwellir.com", "wss://acala.api.onfinality.io/public-ws", "wss://acala.polkawallet.io"],
    karura: ["wss://karura-rpc.dwellir.com", "wss://karura.api.onfinality.io/public-ws", "wss://karura.polkawallet.io"],
    ...(nodeList || []),
  };
  // connect all adapters
  const connected = await firstValueFrom(provider.connectFromChain(chains, nodeList));

  await Promise.all(
    chains.map((chain) => {
      const api = provider.getApiPromise(chain);
      if (chain === "acala" || chain === "karura") {
        const evmProvider = new EvmRpcProvider(nodeList[chain][0]);
        const wallet = new Wallet(api, { evmProvider });
        return availableAdapters[chain].init(api, wallet);
      }

      return availableAdapters[chain].init(api);
    })
  );
  return connected;
}

async function disconnectFromChains() {
  const fromChains = Object.keys(availableAdapters) as ChainId[];
  fromChains.forEach((e) => provider.disconnect(e));
}

async function getFromChainsAll() {
  await _initBridge();

  return Object.keys(availableAdapters).filter((e) => e !== "moonbeam" && e !== "moonriver");
}

async function getRoutes() {
  await _initBridge();

  return bridge.router.getAvailableRouters().map((e) => ({ from: e.from.id, to: e.to.id, token: e.token }));
}

async function getChainsInfo() {
  await _initBridge();

  return chains;
}

async function getNetworkProperties(chain: ChainId) {
  const props = await firstValueFrom(provider.getApi(chain).rpc.system.properties());
  return {
    ss58Format: parseInt(props.ss58Format.toString()),
    tokenDecimals: props.tokenDecimals.toJSON(),
    tokenSymbol: props.tokenSymbol.toJSON(),
  };
}

async function subscribeBalancesInner(chain: ChainId, address: string, callback: Function) {
  await _initBridge();

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

async function subscribeBalances(chain: ChainId, address: string, msgChannel: string) {
  subscribeMessage((<any>window).bridge.subscribeBalancesInner, [chain, address], msgChannel, undefined);
  return;
}

async function getInputConfig(from: ChainId, to: ChainId, token: string, addressInput: string, signer: string) {
  await _initBridge();

  const adapter = bridge.findAdapter(from);

  const address =
    to === "moonbeam" || to === "moonriver" ? addressInput || "0x0000000000000000000000000000000000000000" : addressInput || signer;
  const res = await firstValueFrom(adapter.subscribeInputConfig({ to, token, address, signer }));
  return {
    from,
    to,
    token,
    address,
    decimals: res.minInput.getPrecision(),
    minInput: res.minInput.toChainData().toString(),
    maxInput: res.maxInput.toChainData().toString(),
    destFee: {
      token: res.destFee.token,
      amount: res.destFee.balance.toChainData().toString(),
      decimals: res.destFee.balance.getPrecision(),
    },
    estimateFee: res.estimateFee,
  };
}

async function getTxParams(
  chainFrom: ChainId,
  chainTo: ChainId,
  token: string,
  address: string,
  amount: string,
  decimals: number,
  signer: string
) {
  const adapter = bridge.findAdapter(chainFrom);
  const tx = adapter.createTx({ to: chainTo, token, address, amount: FN.fromInner(amount, decimals), signer });
  return {
    module: tx.method.section,
    call: tx.method.method,
    params: tx.args.map((e) => e.toHuman()),
    txHex: tx.toHex(),
  };
}

async function estimateTxFee(chainFrom: ChainId, txHex: string, sender: string) {
  const tx = getApi(chainFrom).tx(txHex);

  const feeData = await tx.paymentInfo(sender);

  return feeData.partialFee.toString();
}

async function sendTx(chainFrom: ChainId, txInfo: any, password: string, msgId: string, keyPairJson: KeyringPair$Json) {
  return new Promise(async (resolve) => {
    const tx = getApi(chainFrom).tx(txInfo.txHex);

    const onStatusChange = (result: SubmittableResult) => {
      if (result.status.isInBlock || result.status.isFinalized) {
        const { success, error } = _extractEvents(result);
        if (success) {
          resolve({ hash: tx.hash.toString() });
        }
        if (error) {
          resolve({ error });
        }
      } else {
        (<any>window).send(msgId, result.status.type);
      }
    };

    let keyPair = keyring.addFromJson(keyPairJson);
    try {
      keyPair.decodePkcs8(password);
    } catch (err) {
      resolve({ error: "password check failed" });
    }
    tx.signAndSend(keyPair, { tip: new BN(txInfo.tip, 10) }, onStatusChange).catch((err) => {
      resolve({ error: err.message });
    });
  });
}

function _extractEvents(result: SubmittableResult) {
  if (!result || !result.events) {
    return {};
  }

  let success = false;
  let error: string;
  result.events
    .filter((event) => !!event.event)
    .map(({ event: { data, method, section } }) => {
      if (section === "system" && method === "ExtrinsicFailed") {
        const [dispatchError] = (data as unknown) as ITuple<[DispatchError]>;
        error = _getDispatchError(dispatchError);

        (<any>window).send("txUpdateEvent", {
          title: `${section}.${method}`,
          message: error,
        });
      } else {
        (<any>window).send("txUpdateEvent", {
          title: `${section}.${method}`,
          message: "ok",
        });
        if (section == "system" && method == "ExtrinsicSuccess") {
          success = true;
        }
      }
    });
  return { success, error };
}

function _getDispatchError(dispatchError: DispatchError): string {
  let message: string = dispatchError.type;

  if (dispatchError.isModule) {
    try {
      const mod = dispatchError.asModule;
      const error = dispatchError.registry.findMetaError(mod);

      message = `${error.section}.${error.name}`;
    } catch (error) {
      // swallow
    }
  } else if (dispatchError.isToken) {
    message = `${dispatchError.type}.${dispatchError.asToken.type}`;
  }

  return message;
}

function checkPassword(keyPairJson: KeyringPair$Json, pubKey: string, pass: string) {
  return new Promise((resolve) => {
    const keyPair = keyring.addFromJson(keyPairJson);
    try {
      if (!keyPair.isLocked) {
        keyPair.lock();
      }
      keyPair.decodePkcs8(pass);
    } catch (err) {
      resolve(null);
    }
    resolve({ success: true });
  });
}

function getApi(chainName: ChainId) {
  return provider.getApiPromise(chainName);
}

async function checkAddressFormat(address: string, ss58: number) {
  await cryptoWaitReady();
  try {
    const formated = keyring.encodeAddress(keyring.decodeAddress(address), ss58);
    return formated.toUpperCase() == address.toUpperCase();
  } catch (err) {
    (<any>window).send("log", { error: err.message });
    return false;
  }
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
  estimateTxFee,
  sendTx,
  checkPassword,
  checkAddressFormat,
};

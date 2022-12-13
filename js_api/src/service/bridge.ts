import { ApiProvider, BalanceData, Bridge, chains, FN, ChainName } from "@polkawallet/bridge";
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
import { QuartzAdapter } from "@polkawallet/bridge/adapters/unique";
import { KintsugiAdapter, InterlayAdapter } from "@polkawallet/bridge/adapters/interlay";
import { KicoAdapter } from "@polkawallet/bridge/adapters/kico";
import { PichiuAdapter } from "@polkawallet/bridge/adapters/kylin";
import { TuringAdapter } from "@polkawallet/bridge/adapters/oak";
import { ParallelAdapter, HeikoAdapter } from "@polkawallet/bridge/adapters/parallel";
import { KhalaAdapter } from "@polkawallet/bridge/adapters/phala";
import { BasiliskAdapter } from "@polkawallet/bridge/adapters/hydradx";
import { ListenAdapter } from "@polkawallet/bridge/adapters/listen";
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
import axios from "axios";

let keyring = new Keyring({ ss58Format: 0, type: "sr25519" });

const _updateDisabledRoute = async () => {
  const res = await axios.get("https://acala.polkawallet-cloud.com/config/bridge.json");

  if (res.status !== 200) {
    throw new Error("fetch metadata error");
  }

  return res.data.disabledRoute;
};

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
  integritee: new IntegriteeAdapter(),
  interlay: new InterlayAdapter(),
  khala: new KhalaAdapter(),
  kintsugi: new KintsugiAdapter(),
  kico: new KicoAdapter(),
  listen: new ListenAdapter(),
  moonbeam: new MoonbeamAdapter(),
  moonriver: new MoonriverAdapter(),
  parallel: new ParallelAdapter(),
  pichiu: new PichiuAdapter(),
  quartz: new QuartzAdapter(),
  shadow: new ShadowAdapter(),
  shiden: new ShidenAdapter(),
  statemine: new StatemineAdapter(),
  turing: new TuringAdapter(),
};
let bridge: Bridge;

const _initBridge = async () => {
  if (!bridge) {
    const disabledRoute = await _updateDisabledRoute();
    bridge = new Bridge({
      adapters: Object.values(availableAdapters),
      routersDisabled: disabledRoute,
    });

    await bridge.isReady;
  }
};

async function connectFromChains(chains: ChainName[], nodeList: Partial<Record<ChainName, string[]>> | undefined) {
  // connect all adapters
  const connected = await firstValueFrom(provider.connectFromChain(chains, nodeList));

  await Promise.all(chains.map((chain) => availableAdapters[chain].setApi(provider.getApi(chain))));
  return connected;
}

async function disconnectFromChains() {
  const fromChains = Object.keys(availableAdapters) as ChainName[];
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

async function getNetworkProperties(chain: ChainName) {
  const props = await firstValueFrom(provider.getApi(chain).rpc.system.properties());
  return {
    ss58Format: parseInt(props.ss58Format.toString()),
    tokenDecimals: props.tokenDecimals.toJSON(),
    tokenSymbol: props.tokenSymbol.toJSON(),
  };
}

async function subscribeBalancesInner(chain: ChainName, address: string, callback: Function) {
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

async function subscribeBalances(chain: ChainName, address: string, msgChannel: string) {
  subscribeMessage((<any>window).bridge.subscribeBalancesInner, [chain, address], msgChannel, undefined);
  return;
}

async function getInputConfig(from: ChainName, to: ChainName, token: string, address: string, signer: string) {
  await _initBridge();

  const adapter = bridge.findAdapter(from);

  const res = await firstValueFrom(adapter.subscribeInputConfigs({ to, token, address, signer }));
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
  chainFrom: ChainName,
  chainTo: ChainName,
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

async function estimateTxFee(chainFrom: ChainName, txHex: string, sender: string) {
  const tx = getApi(chainFrom).tx(txHex);

  const feeData = await tx.paymentInfo(sender);

  return feeData.partialFee.toString();
}

async function sendTx(chainFrom: ChainName, txInfo: any, password: string, msgId: string, keyPairJson: KeyringPair$Json) {
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

function getApi(chainName: ChainName) {
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

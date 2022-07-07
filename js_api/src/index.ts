import { WsProvider, ApiPromise } from "@polkadot/api";
import { ScProvider } from "@polkadot/rpc-provider/substrate-connect";
import { KUSAMA_GENESIS, POLKADOT_GENESIS, STATEMINE_GENESIS } from "./constants/networkSpect";
import localMetadata from "./constants/networkMetadata";
import { subscribeMessage, getNetworkConst, getNetworkProperties } from "./service/setting";
import keyring from "./service/keyring";
import account from "./service/account";
import staking from "./service/staking";
// import wc from "./service/walletconnect";
import gov from "./service/gov";
import parachain from "./service/parachain";
import assets from "./service/assets";
import { genLinks } from "./utils/config/config";

// console.log will send message to MsgChannel to App
function send(path: string, data: any) {
  console.log(JSON.stringify({ path, data }));
}
send("log", "main js loaded");
(<any>window).send = send;

/**
 * connect to one a specific chain with an embeded light node
 *
 * @param {string} json raw chain spec
 */
 async function connectLightNode(chainSpec: string[]) {
  (<any>window).api = undefined;

  return new Promise<void>(async (resolve, reject) => {
    const provider = new ScProvider(chainSpec);
    await provider.connect();
    try {
      const res = await ApiPromise.create({
        provider,
      });
      if (!(<any>window).api) {
        (<any>window).api = res;
        send("log", `connected success to local light node`);
        resolve();
      } else {
        res.disconnect();
        send("log", `connection to local light node was success and disconnected`);
        resolve();
      }
    } catch (err) {
      send("log", `connect failed`);
      provider.disconnect();
      resolve();
    }
  });
 }

async function connectAll(nodes: string[]) {
  return Promise.race(nodes.map((node) => connect([node])));
}

/**
 * connect to a specific node.
 *
 * @param {string} nodeEndpoint
 */
async function connect(nodes: string[]) {
  (<any>window).api = undefined;

  return new Promise(async (resolve, reject) => {
    const wsProvider = new WsProvider(nodes);
    try {
      const res = await ApiPromise.create({
        provider: wsProvider,
        metadata: {
          [`${KUSAMA_GENESIS}-9122`]: localMetadata["kusama"],
          [`${POLKADOT_GENESIS}-9122`]: localMetadata["polkadot"],
          [`${STATEMINE_GENESIS}-504`]: localMetadata["statemine"],
        } as any,
      });
      if (!(<any>window).api) {
        (<any>window).api = res;
        const url = nodes[(<any>res)._options.provider.__private_23_endpointIndex];
        send("log", `${url} wss connected success`);
        resolve(url);
      } else {
        res.disconnect();
        const url = nodes[(<any>res)._options.provider.__private_23_endpointIndex];
        send("log", `${url} wss success and disconnected`);
        resolve(url);
      }
    } catch (err) {
      send("log", `connect failed`);
      wsProvider.disconnect();
      resolve(null);
    }
  });
}

const test = async () => {
  // const props = await api.rpc.system.properties();
  // send("log", props);
};

const settings = {
  test,
  connect,
  connectAll,
  subscribeMessage,
  getNetworkConst,
  getNetworkProperties,
  // generate external links to polkascan/subscan/polkassembly...
  genLinks,
};

(<any>window).settings = settings;
(<any>window).keyring = keyring;
(<any>window).account = account;
(<any>window).staking = staking;
(<any>window).gov = gov;
(<any>window).parachain = parachain;
(<any>window).assets = assets;

// walletConnect supporting is not ready.
// (<any>window).walletConnect = wc;

export default settings;

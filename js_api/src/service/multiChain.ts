import { ApiPromise, WsProvider } from "@polkadot/api";

const nodeList: Record<string, string[]> = {
  kusamaPeople: ["wss://people-kusama-rpc.dwellir.com", "wss://kusama-people-rpc.polkadot.io", "wss://ksm-rpc.stakeworld.io/people"],
  // people: [],
};

const parachainApis: Record<string, ApiPromise> = {};
async function connectParachain(chainName: string): Promise<string | undefined> {
  try {
    if (parachainApis[chainName]) {
      return chainName;
    }

    const wsProvider = new WsProvider(nodeList[chainName]);
    const res = await ApiPromise.create({
      provider: wsProvider,
    });

    parachainApis[chainName] = res;

    return chainName;
  } catch (err) {
    console.error(`connect parachain ${chainName} failed:`, err);
    return undefined;
  }
}

function getParachainApi(chainName: number): ApiPromise | undefined {
  return parachainApis[chainName];
}

export default { connectParachain, getParachainApi };

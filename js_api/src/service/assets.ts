import { ApiPromise } from "@polkadot/api";

/**
 * get assets ids of statemine/statemint network.
 */
async function getAssetsAll(api: ApiPromise) {
  const entries = await api.query.assets.metadata.entries();
  return entries
    .map(([{ args: [assetId] }, data]) => ({
      id: assetId.toNumber(),
      ...data.toHuman(),
    }))
    .sort((a, b) => a.id - b.id);
}

export default {
  getAssetsAll,
};

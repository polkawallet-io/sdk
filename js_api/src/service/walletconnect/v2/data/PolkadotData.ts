/**
 * Types
 */
export type TPolkadotChain = keyof typeof POLKADOT_MAINNET_CHAINS;

/**
 * Chains:
 * Recording to https://github.com/ChainAgnostic/CAIPs/issues/13,
 * ChainId is the first 32 characters of the genesis hash.
 */
export const POLKADOT_MAINNET_CHAINS = {
  "polkadot:91b171bb158e2d3848fa23a9f1c25182": {
    chainId: "91b171bb158e2d3848fa23a9f1c25182",
    name: "Polkadot",
  },
  "polkadot:b0a8d493285c2df73290dfb7e61f870f": {
    chainId: "b0a8d493285c2df73290dfb7e61f870f",
    name: "Kusama",
  },
  "polkadot:68d56f15f85d3136970ec16946040bc1": {
    chainId: "68d56f15f85d3136970ec16946040bc1",
    name: "Statemint",
  },
  "polkadot:48239ef607d7928874027a43a6768920": {
    chainId: "48239ef607d7928874027a43a6768920",
    name: "Statemine",
  },
  "polkadot:fc41b9bd8ef8fe53d58c7ea67c794c7e": {
    chainId: "fc41b9bd8ef8fe53d58c7ea67c794c7e",
    name: "Acala",
  },
  "polkadot:baf5aabe40646d11f0ee8abbdc64f4a4": {
    chainId: "baf5aabe40646d11f0ee8abbdc64f4a4",
    name: "Karura",
  },
};

/**
 * Methods
 */
export const POLKADOT_SIGNING_METHODS = {
  POLKADOT_SIGN_TRANSACTION: "polkadot_signTransaction",
  POLKADOT_SIGN_MESSAGE: "polkadot_signMessage",
};

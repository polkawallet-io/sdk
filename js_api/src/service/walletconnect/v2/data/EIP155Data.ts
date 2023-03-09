/**
 * @desc Refference list of eip155 chains
 * @url https://chainlist.org
 */

/**
 * Types
 */
export type TEIP155Chain = keyof typeof EIP155_CHAINS;

/**
 * Chains
 */
export const EIP155_MAINNET_CHAINS = {
  "eip155:1": {
    chainId: 1,
    name: "Ethereum",
    rpc: "https://cloudflare-eth.com/",
  },
};

export const EIP155_TEST_CHAINS = {
  "eip155:5": {
    chainId: 5,
    name: "Ethereum Goerli",
    rpc: "https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161",
  },
  "eip155:596": {
    chainId: 596,
    name: "Karura Testnet",
    rpc: "https://eth-rpc-karura-testnet.aca-staging.network/eth/http",
  },
  "eip155:597": {
    chainId: 597,
    name: "Acala Testnet",
    rpc: "https://eth-rpc-acala-testnet.aca-staging.network/eth/http",
  },
};

export const EIP155_CHAINS = { ...EIP155_MAINNET_CHAINS, ...EIP155_TEST_CHAINS };

/**
 * Methods
 */
export const EIP155_SIGNING_METHODS = {
  PERSONAL_SIGN: "personal_sign",
  ETH_SIGN: "eth_sign",
  ETH_SIGN_TRANSACTION: "eth_signTransaction",
  ETH_SIGN_TYPED_DATA: "eth_signTypedData",
  ETH_SIGN_TYPED_DATA_V3: "eth_signTypedData_v3",
  ETH_SIGN_TYPED_DATA_V4: "eth_signTypedData_v4",
  ETH_SEND_RAW_TRANSACTION: "eth_sendRawTransaction",
  ETH_SEND_TRANSACTION: "eth_sendTransaction",
};

const network_ss58_map = {
  'acala': 42,
  'laminar': 42,
  'kusama': 2,
  'substrate': 42,
  'polkadot': 0,
};

const SigningMethodsEVM = [
  "eth_sendTransaction",
  "eth_signTransaction",
  "eth_sign",
  "eth_signTypedData",
  "eth_signTypedData_v1",
  "eth_signTypedData_v2",
  "eth_signTypedData_v3",
  "eth_signTypedData_v4",
  "personal_sign",
  "wallet_addEthereumChain",
  "wallet_switchEthereumChain",
  "wallet_getPermissions",
  "wallet_requestPermissions",
  "wallet_registerOnboarding",
  "wallet_watchAsset",
  "wallet_scanQRCode",
  // wallet auth methods
  "eth_chainId",
  "eth_requestAccounts",
  "eth_accounts",
  "metamask_getProviderState",
];

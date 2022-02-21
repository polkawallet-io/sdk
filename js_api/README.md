# js_api

Wrap `@polkadot-js/api` to provide APIs for polkawallet/sdk.

@polkadot-js/api: ^7.9.1

## build & test

To build:

```bash
yarn install
yarn run build
```

To test:
open `./test/index.html` in chrome.
open chrome dev console and run `runTests().then(console.log)`

### `polkadot-js/api` hack

1. remove `connectWithRetry()` in `node_modules/@polkadot/rpc-provider/ws/index.js` to avoid auto-connect.
2. replace value of `packageInfo.path` in `node_modules/@polkadot/api/packageInfo.js` to avoid `Invalid URL` issue in webview.
3. lock `bn.js: 4.12.0` to avoid [this issue](https://github.com/polkadot-js/api/issues/4024).

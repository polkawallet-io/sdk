import { ApiPromise } from "@polkadot/api";
import SignClient from "@walletconnect/sign-client";
import { SignClientTypes, EngineTypes, SessionTypes } from "@walletconnect/types";
import { ERROR } from "@walletconnect/utils";

import { Keyring } from "@polkadot/keyring";
import { hexToU8a, u8aToHex, isHex, stringToU8a } from "@polkadot/util";

import { formatJsonRpcResult } from "./jsonRpc";

let client: SignClient;

async function initClient() {
  if (!client) {
    client = await SignClient.init({
      projectId: "45587a9eca50f3e95b99ef96a0a898f2",
      relayUrl: "wss://relay.walletconnect.com",
      metadata: {
        name: "Polkawallet",
        description: "Mobile Wallet for Polkadot Eco.",
        url: "https://polkwallet.io/",
        icons: ["https://polkawallet.io/images/favicon-icon.png"],
      },
    });

    client.on("session_proposal", async (proposal: SignClientTypes.EventArguments["session_proposal"]) => {
      //   // user should be prompted to approve the proposed session permissions displaying also dapp metadata
      //   const { proposer, permissions } = proposal;
      //   const { metadata } = proposer;
      //   let approved: boolean;
      //   handleSessionUserApproval(approved, proposal); // described in the step 4
      (<any>window).send("walletConnectPairing", proposal);
    });

    // client.on(CLIENT_EVENTS.session.created, async (session: SessionTypes.Created) => {
    //   // session created succesfully
    //   (<any>window).send("walletConnectCreated", session);
    // });

    client.on("session_request", async (requestEvent: SignClientTypes.EventArguments["session_request"]) => {
      (<any>window).send("walletConnectPayload", requestEvent);

      //   // WalletConnect client can track multiple sessions
      //   // assert the topic from which application requested
      //   const { topic, payload } = payloadEvent;
      //   const session = await client.session.get(payloadEvent.topic);
      //   // now you can display to the user for approval using the stored metadata
      //   const { metadata } = session.peer;
      //   // after user has either approved or not the request it should be formatted
      //   // as response with either the result or the error message
      //   let result: any;
      //   const response = approved
      //     ? {
      //         topic,
      //         response: {
      //           id: payload.id,
      //           jsonrpc: "2.0",
      //           result,
      //         },
      //       }
      //     : {
      //         topic,
      //         response: {
      //           id: payload.id,
      //           jsonrpc: "2.0",
      //           error: {
      //             code: -32000,
      //             message: "User rejected JSON-RPC request",
      //           },
      //         },
      //       };
      //   await client.respond(response);
    });
  }
}
async function connect(uri: string) {
  client.pair({ uri });
  return {};
}
async function disconnect(param: EngineTypes.DisconnectParams) {
  if (client) {
    client.disconnect(param);
  }
  return {};
}

async function approveProposal(proposal: SignClientTypes.EventArguments["session_proposal"], address: string) {
  // const response: SessionTypes.Response = {
  //   metadata: {
  //     name: "Polkawallet",
  //     description: "Mobile wallet for polkadot ecosystem.",
  //     url: "#",
  //     icons: ["https://polkawallet.io/images/logo.png"],
  //   },
  //   state: {
  //     accounts: [address],
  //   },
  // };

  // Get required proposal data
  const { id, params } = proposal;
  const { proposer, requiredNamespaces, relays } = params;

  const namespaces: SessionTypes.Namespaces = {};
  Object.keys(requiredNamespaces).forEach((key) => {
    const accounts: string[] = [];
    requiredNamespaces[key].chains.map((chain) => {
      [address].map((acc) => accounts.push(`${chain}:${acc}`));
    });
    namespaces[key] = {
      accounts,
      methods: requiredNamespaces[key].methods,
      events: requiredNamespaces[key].events,
    };
  });

  const { acknowledged } = await client.approve({ id, relayProtocol: relays[0].protocol, namespaces });
  await acknowledged();
  return {};
}

async function rejectProposal(proposal: SignClientTypes.EventArguments["session_proposal"]) {
  await client.reject({ id: proposal.id, reason: ERROR.JSONRPC_REQUEST_METHOD_REJECTED.format() });
  return {};
}

async function payloadRespond(topic: string, response: any) {
  await client.respond({ topic, response });
  return {};
}

async function signPayload(api: ApiPromise, { id, params: { request } }, password: string) {
  const { method, params } = request;
  const address = params[0];
  const keyPair = ((window as any).keyring as Keyring).getPair(address);
  try {
    if (!keyPair.isLocked) {
      keyPair.lock();
    }
    keyPair.decodePkcs8(password);

    if (method == "signExtrinsic") {
      const txInfo = params[1];
      const { header, mortalLength, nonce } = (await api.derive.tx.signingInfo(address)) as any;
      const tx = api.tx[txInfo.module][txInfo.call](...txInfo.params);

      const signerPayload = api.registry.createType("SignerPayload", {
        address,
        blockHash: header.hash,
        blockNumber: header ? header.number : 0,
        era: api.registry.createType("ExtrinsicEra", {
          current: header.number,
          period: mortalLength,
        }),
        genesisHash: api.genesisHash,
        method: tx.method,
        nonce,
        signedExtensions: ["CheckNonce"],
        tip: txInfo.tip,
        runtimeVersion: {
          specVersion: api.runtimeVersion.specVersion,
          transactionVersion: api.runtimeVersion.transactionVersion,
        },
        version: api.extrinsicVersion,
      });
      const payload = signerPayload.toPayload();
      const txPayload = api.registry.createType("ExtrinsicPayload", payload, {
        version: payload.version,
      });
      const signed = txPayload.sign(keyPair);
      return formatJsonRpcResult(id, signed);
    }
    if (method == "signBytes") {
      const msg = params[1];
      const isDataHex = isHex(msg);
      return formatJsonRpcResult(id, {
        signature: u8aToHex(keyPair.sign(isDataHex ? hexToU8a(msg) : stringToU8a(msg))),
      });
    }
  } catch (err) {
    return { id, jsonrpc: "2.0", error: err.message };
  }
}

export default {
  initClient,
  connect,
  disconnect,
  approveProposal,
  rejectProposal,
  payloadRespond,
  signPayload,
};

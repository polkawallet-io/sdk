import { ApiPromise } from "@polkadot/api";
import WalletConnectClient, { CLIENT_EVENTS } from "@walletconnect/client";
import { SessionTypes, ClientTypes } from "@walletconnect/types";

import { Keyring } from "@polkadot/keyring";
import { hexToU8a, u8aToHex, isHex, stringToU8a } from "@polkadot/util";

let client: WalletConnectClient;

async function initClient() {
  if (!client) {
    client = await WalletConnectClient.init({
      relayProvider: "wss://staging.walletconnect.org",
    });

    client.on(CLIENT_EVENTS.session.proposal, async (proposal: SessionTypes.Proposal) => {
      //   // user should be prompted to approve the proposed session permissions displaying also dapp metadata
      //   const { proposer, permissions } = proposal;
      //   const { metadata } = proposer;
      //   let approved: boolean;
      //   handleSessionUserApproval(approved, proposal); // described in the step 4
      (<any>window).send("walletConnectPairing", proposal);
    });

    client.on(CLIENT_EVENTS.session.created, async (session: SessionTypes.Created) => {
      // session created succesfully
      (<any>window).send("walletConnectCreated", session);
    });

    client.on(CLIENT_EVENTS.session.payload, async (payloadEvent: SessionTypes.PayloadEvent) => {
      (<any>window).send("walletConnectPayload", payloadEvent);

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
async function disconnect(param: SessionTypes.DeleteParams) {
  if (client) {
    client.session.delete(param);
  }
  return {};
}

async function approveProposal(proposal: SessionTypes.Proposal, address: string) {
  const response: SessionTypes.Response = {
    metadata: {
      name: "Polkawallet",
      description: "Mobile wallet for polkadot ecosystem.",
      url: "#",
      icons: ["https://polkawallet.io/images/logo.png"],
    },
    state: {
      accounts: [address],
    },
  };
  await client.approve({ proposal, response });
  return {};
}

async function rejectProposal(proposal: SessionTypes.Proposal) {
  await client.reject({ proposal });
  disconnect({
    topic: proposal.topic,
    reason: "user rejected pairing",
  });
  return {};
}

async function payloadRespond(response: any) {
  await client.respond(response);
  return {};
}

async function signPayload(api: ApiPromise, { payload }, password: string) {
  const { method, params } = payload;
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
      return signed;
    }
    if (method == "signBytes") {
      const msg = params[1];
      const isDataHex = isHex(msg);
      return {
        signature: u8aToHex(keyPair.sign(isDataHex ? hexToU8a(msg) : stringToU8a(msg))),
      };
    }
  } catch (err) {
    (window as any).send({ error: err.message });
  }

  return {};
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

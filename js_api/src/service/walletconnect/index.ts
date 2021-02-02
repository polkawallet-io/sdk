import WalletConnectClient, { CLIENT_EVENTS } from "@walletconnect/client";
import { SessionTypes, ClientTypes } from "@walletconnect/types";

let client: WalletConnectClient;
let initiated = false;

async function connect(uri: string) {
  if (!client) {
    client = await WalletConnectClient.init({
      relayProvider: "wss://staging.walletconnect.org",
    });
  } else {
    initiated = true;
  }

  return new Promise((resolve, reject) => {
    if (!initiated) {
      client.on(CLIENT_EVENTS.session.proposal, async (proposal: SessionTypes.Proposal) => {
        //   // user should be prompted to approve the proposed session permissions displaying also dapp metadata
        //   const { proposer, permissions } = proposal;
        //   const { metadata } = proposer;
        //   let approved: boolean;
        //   handleSessionUserApproval(approved, proposal); // described in the step 4
        resolve(proposal);
      });

      client.on(CLIENT_EVENTS.session.created, async (session: SessionTypes.Created) => {
        // session created succesfully
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

    client.pair({ uri });
  });
}
async function disconnect(param: ClientTypes.DisconnectParams) {
  if (client) {
    client.disconnect(param);
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
  return {};
}

async function payloadRespond(response: any) {
  await client.respond(response);
  return {};
}

export default {
  connect,
  disconnect,
  approveProposal,
  rejectProposal,
  payloadRespond,
};

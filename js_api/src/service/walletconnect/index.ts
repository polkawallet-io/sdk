import { parseUri } from "@walletconnect/utils";

import ClientApp from "./v1/client";
import Client2 from "./v2/client";

const wc = new ClientApp();

const wc2 = new Client2();
setTimeout(() => {
  wc2.initWalletConnect();
}, 500);

async function initConnect(uri: string, address: string, chainId: number) {
  const { version } = parseUri(uri);

  // Route the provided URI to the v1 SignClient if URI version indicates it, else use v2.
  if (version === 1) {
    wc.onURIReceive(uri, address, chainId);
  } else {
    if (!wc2.state.connector) {
      await wc2.initWalletConnect();
    }
    wc2.onURIReceive(uri, address);
  }
}

async function reConnectSession(session: any) {
  wc.reConnectSession(session);
}

/**
 * User will see a confirm dialog while wc client received 'session_request' from DApp.
 * Then user will confirm approve or reject the connection.
 */
async function confirmConnect(approve: boolean) {
  if (approve) {
    wc.approveSession();
  } else {
    wc.rejectSession();
  }
}

async function disconnect() {
  wc.killSession();
  wc2.killSession();
}

async function confirmCallRequest(id: number, approve: boolean, pass: string, gasOptions: any) {
  return new Promise((resolve) => {
    if (approve) {
      wc.approveRequest(id, pass, gasOptions, (res: any) => {
        resolve(res);
      });
    } else {
      wc.rejectRequest(id);
      resolve({});
    }
  });
}

async function updateSession(sessionParams: { chainId?: number; address?: string }) {
  wc.updateSession(sessionParams);
}

async function confirmConnectV2(approve: boolean, address: string) {
  if (approve) {
    wc2.approveSession(address);
  } else {
    wc2.rejectSession();
  }
}

async function confirmCallRequestV2(id: number, approve: boolean, pass: string, gasOptions: any) {
  return new Promise((resolve) => {
    if (approve) {
      wc2.approveRequest(id, pass, gasOptions, (res: any) => {
        resolve(res);
      });
    } else {
      wc2.rejectRequest(id);
      resolve({});
    }
  });
}

async function updateSessionV2(sessionParams: { chainId?: string; address?: string }) {
  wc2.updateSession(sessionParams);
}

export default {
  initConnect,
  reConnectSession,
  confirmConnect,
  updateSession,
  disconnect,
  confirmCallRequest,

  // wallet-connect v2:
  confirmConnectV2,
  confirmCallRequestV2,
  updateSessionV2,
};

import { parseUri } from "@walletconnect/utils";

import ClientApp from "./v1/client";
import Client2 from "./v2/client";

const wc = new ClientApp();

const wc2 = new Client2();

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
  return wc2.updateSession(sessionParams);
}

async function injectCacheDataV2(cache: { pairing: string; session: string; subscription: string; keychain: string }, address: string) {
  if (cache.keychain) {
    localStorage.setItem("wc@2:core:0.3//keychain", cache.keychain);
  }
  if (cache.subscription) {
    localStorage.setItem("wc@2:core:0.3//subscription", cache.subscription);
  }
  if (cache.pairing) {
    localStorage.setItem("wc@2:core:0.3//pairing", cache.pairing);
  }

  let sessionTopic: string;
  if (cache.session && JSON.parse(cache.session).length > 0) {
    localStorage.setItem("wc@2:client:0.3//session", cache.session);
    sessionTopic = JSON.parse(cache.session)[0].topic;
  }

  wc2.initWalletConnect();

  if (sessionTopic) {
    wc2.restoreFromCache(sessionTopic, address);
  }
}

async function deletePairingV2(pairingTopic: string) {
  wc2.killSession(pairingTopic);
}

async function disconnectV2(sessionTopic: string) {
  wc2.killSession(sessionTopic);
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
  injectCacheDataV2,
  deletePairingV2,
  disconnectV2,
};

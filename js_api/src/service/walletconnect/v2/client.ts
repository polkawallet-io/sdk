import SignClient from "@walletconnect/sign-client";
import { DEFAULT_CHAIN_ID } from "../v1/constants";
import { getRpcEngine } from "../engines";
import { notifyWallet } from "./helpers/wallet";

import keyring from "../../keyring";
import ethKeyring from "../../eth/keyring";
import { REGIONALIZED_RELAYER_ENDPOINTS } from "./data/RelayerRegions";
import { SessionTypes, SignClientTypes } from "@walletconnect/types";
import { getSdkError } from "@walletconnect/utils";
import { formatJsonRpcError } from "../engines/ethereum";
import { EIP155_CHAINS, EIP155_MAINNET_CHAINS } from "./data/EIP155Data";
import { POLKADOT_MAINNET_CHAINS } from "./data/PolkadotData";
import { WC_PROJECT_ID } from "../../../config.local";

export interface IAppState2 {
  loading: boolean;
  connector: SignClient | null;
  topic: string;
  uri: string;
  proposal: SignClientTypes.EventArguments["session_proposal"];
  connected: boolean;
  chainId: string;
  address: string;
  requests: any[];
  results: any[];
}

export const INITIAL_STATE: IAppState2 = {
  loading: false,
  connector: null,
  topic: "",
  uri: "",
  proposal: null,
  connected: false,
  chainId: DEFAULT_CHAIN_ID.toString(),
  address: "",
  requests: [],
  results: [],
};

class Client2 {
  public state: IAppState2;

  constructor() {
    this.state = {
      ...INITIAL_STATE,
    };
  }

  private setState(data: Partial<IAppState2>) {
    this.state = {
      ...this.state,
      ...data,
    };
  }

  public bindedSetState = (newState: Partial<IAppState2>) => this.setState(newState);

  public initWalletConnect = async () => {
    this.setState({ loading: true });

    try {
      const signClient = await SignClient.init({
        projectId: WC_PROJECT_ID,
        relayUrl: REGIONALIZED_RELAYER_ENDPOINTS[0].value,
        metadata: {
          name: "Polkawallet",
          description: "Mobile Wallet for Dotsama eco.",
          url: "https://pokawallet.io/",
          icons: ["https://raw.githubusercontent.com/polkawallet-io/app/master/assets/images/icon.png"],
        },
      });

      this.subscribeToEvents(signClient);

      this.setState({ connector: signClient, loading: false });
    } catch (error) {
      this.setState({ loading: false });

      throw error;
    }
  };

  public approveSession = async (address: string) => {
    // console.log("ACTION", "approveSession");
    const { proposal, connector } = this.state;
    if (proposal) {
      const { id, params } = proposal;
      const { requiredNamespaces, relays } = params;
      const namespaces: SessionTypes.Namespaces = {};

      let chainId: string;
      const isEthAddress = address.startsWith("0x");
      // approve eip155 if address starts with '0x',
      // otherwise approve substrate
      Object.keys(requiredNamespaces).forEach((key) => {
        const accounts: string[] = [];
        if (isEthAddress && key === "eip155") {
          requiredNamespaces[key].chains?.map((chain) => {
            // TODO: remove testnet
            // if (Object.keys(EIP155_MAINNET_CHAINS).includes(chain)) {
            if (Object.keys(EIP155_CHAINS).includes(chain)) {
              chainId = EIP155_CHAINS[chain].chainId.toString();
              accounts.push(`${chain}:${address}`);
            }
          });
        } else if (!isEthAddress && key === "polkadot") {
          requiredNamespaces[key].chains?.map((chain) => {
            if (Object.keys(POLKADOT_MAINNET_CHAINS).includes(chain)) {
              chainId = POLKADOT_MAINNET_CHAINS[chain].chainId;
              accounts.push(`${chain}:${address}`);
            }
          });
        }

        namespaces[key] = {
          accounts,
          methods: requiredNamespaces[key].methods,
          events: requiredNamespaces[key].events,
        };
      });

      const { acknowledged } = await connector.approve({
        id,
        relayProtocol: relays[0].protocol,
        namespaces,
      });
      const session = await acknowledged();

      this.setState({ connected: true, address, chainId, topic: session.topic });

      notifyWallet({
        event: "connect",
        session: {
          topic: session.topic,
          peerMeta: proposal.params.proposer.metadata,
          namespaces: session.namespaces,
          expiry: session.expiry,
          storage: {
            pairing: localStorage.getItem("wc@2:core:0.3//pairing"),
            session: localStorage.getItem("wc@2:client:0.3//session"),
            subscription: localStorage.getItem("wc@2:core:0.3//subscription"),
            keychain: localStorage.getItem("wc@2:core:0.3//keychain"),
          },
        },
      });
    }
  };

  public rejectSession = async () => {
    // console.log("ACTION", "rejectSession");
    const { proposal, connector } = this.state;
    if (proposal && connector) {
      await connector.reject({
        id: proposal.id,
        reason: getSdkError("USER_REJECTED_METHODS"),
      });
    }
  };

  public killSession = (pairingTopic?: string) => {
    // console.log("ACTION", "killSession");
    const { connector, topic } = this.state;
    if (connector) {
      connector.disconnect({
        topic: pairingTopic || topic,
        reason: getSdkError("USER_DISCONNECTED"),
      });
    }
  };

  public subscribeToEvents = (connector: SignClient) => {
    // console.log("ACTION", "subscribeToEvents");

    if (connector) {
      connector.on("session_proposal", (proposal: SignClientTypes.EventArguments["session_proposal"]) => {
        // console.log("EVENT", "session_proposal");
        // console.log("SESSION_PROPOSAL", payload.params);

        this.setState({ proposal });

        notifyWallet({
          event: "session_proposal",
          proposal: proposal,
          uri: `wc:${proposal.params.pairingTopic}@2?relay-protocol=irn`,
        });
      });

      connector.on("session_update", (data) => {
        // console.log("EVENT", "session_update");
      });

      connector.on("session_request", async (requestEvent: SignClientTypes.EventArguments["session_request"]) => {
        // tslint:disable-next-line
        // console.log("session_request", requestEvent);
        const { params, id } = requestEvent;
        const { request } = params;

        await getRpcEngine().router({ id, ...request }, this.state, this.bindedSetState);

        const paramsHuman = getRpcEngine().render(request);
        notifyWallet({ event: "call_request", id, topic: this.state.topic, params: paramsHuman });
      });

      connector.on("session_delete", ({ topic }) => {
        // console.log("EVENT", "session_delete");

        notifyWallet({ event: "disconnect", topic });
      });
    }
  };

  public updateSession = async (sessionParams: { chainId?: string; address?: string }) => {
    const { connector, chainId, address, topic } = this.state;
    const newChainId = sessionParams.chainId || chainId;
    const newAddress = sessionParams.address || address;
    if (connector) {
      const session = connector.session.get(topic);
      const namespaces: SessionTypes.Namespaces = {};
      Object.keys(session.requiredNamespaces).forEach((key) => {
        const chains = [`${address.startsWith("0x") ? "eip155" : "polkadot"}:${newChainId}`];
        const accounts: string[] = [];
        chains?.map((chain) => {
          accounts.push(`${chain}:${newAddress}`);
        });
        namespaces[key] = {
          accounts,
          chains,
          methods: session.requiredNamespaces[key].methods,
          events: session.requiredNamespaces[key].events,
        };
      });
      await connector.update({
        topic,
        namespaces,
      });
      this.setState({
        connector,
        address: newAddress,
        chainId: newChainId,
      });
      return {
        pairing: localStorage.getItem("wc@2:core:0.3//pairing"),
        session: localStorage.getItem("wc@2:client:0.3//session"),
        subscription: localStorage.getItem("wc@2:core:0.3//subscription"),
        keychain: localStorage.getItem("wc@2:core:0.3//keychain"),
      };
    }
    throw new Error("wallet-connect: no connector found.");
  };

  public updateChain = async (chainId: number | string) => {
    await this.updateSession({ chainId: chainId.toString() });
  };

  public onURIReceive = async (data: any, address: string) => {
    const uri = typeof data === "string" ? data : "";
    if (uri) {
      this.setState({ address });
      await this.state.connector.pair({ uri });
    }
  };

  public restoreFromCache = async (sessionTopic: string, address: string) => {
    this.setState({ address, topic: sessionTopic });
  };

  public onQRCodeError = (error: Error) => {
    throw error;
  };

  public closeRequest = async (id: number) => {
    const { requests } = this.state;
    const filteredRequests = requests.filter((request) => request.id !== id);
    this.setState({
      requests: filteredRequests,
    });
  };

  public approveRequest = async (id: number, pass: string, gasOptions: any, callback: Function) => {
    const { topic, connector, requests, address } = this.state;

    const payload = requests.find((e) => e.id === id);
    if (!payload) {
      console.error("call request id no match.");

      callback({ error: "call request id no match." });
      return;
    }

    const isSubstrate = payload.method.startsWith("polkadot_");
    const checkPass: any = await (isSubstrate ? keyring.checkPasswordByAddress(address, pass) : ethKeyring.checkPassword(address, pass));
    if (!checkPass.success) {
      console.error("invalid password.");

      callback({ error: "invalid password." });
      return;
    }

    try {
      const result = await getRpcEngine().signer(payload, this.state, pass, gasOptions);
      callback(result);
    } catch (error) {
      console.error(error);
      callback({ error });
      if (connector) {
        connector.respond({ topic, response: formatJsonRpcError(payload.id, { message: "Failed or Rejected Request" }) });
      }
    }

    this.closeRequest(id);
    this.setState({ connector });
  };

  public rejectRequest = async (id: number) => {
    const { topic, connector } = this.state;
    if (connector) {
      connector.respond({ topic, response: formatJsonRpcError(id, { message: "Failed or Rejected Request" }) });
    }
    await this.closeRequest(id);
    this.setState({ connector });
  };
}

export default Client2;

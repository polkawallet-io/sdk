import SignClient from "@walletconnect/sign-client";
import { DEFAULT_CHAIN_ID } from "../v1/constants";
import { getRpcEngine } from "../engines";
import { notifyWallet } from "../v1/helpers/wallet";

import keyring from "../../keyring";
import ethKeyring from "../../eth/keyring";
import { REGIONALIZED_RELAYER_ENDPOINTS } from "./data/RelayerRegions";
import { SessionTypes, SignClientTypes } from "@walletconnect/types";
import { getSdkError, parseUri } from "@walletconnect/utils";
import { formatJsonRpcError } from "../engines/ethereum";
import { EIP155_CHAINS, EIP155_MAINNET_CHAINS } from "./data/EIP155Data";
import { POLKADOT_MAINNET_CHAINS } from "./data/PolkadotData";

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
        logger: "debug",
        projectId: "45587a9eca50f3e95b99ef96a0a898f2",
        relayUrl: REGIONALIZED_RELAYER_ENDPOINTS[0].value,
        metadata: {
          name: "Polkawallet",
          description: "Mobile Wallet for Dotsama eco.",
          url: "https://pokawallet.io/",
          icons: ["https://raw.githubusercontent.com/polkawallet-io/app/master/assets/images/icon.png"],
        },
      });

      this.setState({
        loading: false,
        connector: signClient,
      });

      this.subscribeToEvents();
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
              accounts.push(`${chain}:${address}`);
            }
          });
        } else if (!isEthAddress && key === "polkadot") {
          requiredNamespaces[key].chains?.map((chain) => {
            if (Object.keys(POLKADOT_MAINNET_CHAINS).includes(chain)) {
              accounts.push(`${chain}:${address}`);
            }
          });
        }
        if (accounts.length > 0) {
          namespaces[key] = {
            accounts,
            methods: requiredNamespaces[key].methods,
            events: requiredNamespaces[key].events,
          };
        }
      });

      const { acknowledged } = await connector.approve({
        id,
        relayProtocol: relays[0].protocol,
        namespaces,
      });
      const session = await acknowledged();

      this.setState({ connected: true, address, topic: session.topic });

      notifyWallet({ event: "connect", session: { peerMeta: proposal.params.proposer.metadata } });
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
      this.resetApp();
    }
  };

  public killSession = () => {
    // console.log("ACTION", "killSession");
    const { proposal, connector } = this.state;
    if (proposal && connector) {
      connector.disconnect({
        topic: proposal.params.pairingTopic,
        reason: getSdkError("USER_DISCONNECTED"),
      });
    }
    this.resetApp();
  };

  public resetApp = async () => {
    this.setState({ ...INITIAL_STATE });
  };

  public subscribeToEvents = () => {
    // console.log("ACTION", "subscribeToEvents");
    const { connector } = this.state;

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
        // const requestSession = this.state.connector.session.get(topic);

        await getRpcEngine().router({ id, ...request }, this.state, this.bindedSetState);

        const paramsHuman = getRpcEngine().render(request);
        notifyWallet({ event: "call_request", id, params: paramsHuman });
      });

      connector.on("session_delete", (_) => {
        // console.log("EVENT", "session_delete");

        notifyWallet({ event: "disconnect" });

        this.resetApp();
      });

      // connector.on("disconnect", (error, payload) => {
      //   // console.log("EVENT", "disconnect");

      //   if (error) {
      //     throw error;
      //   }

      //   notifyWallet({ event: "disconnect" });

      //   this.resetApp();
      // });

      this.setState({ connector });
    }
  };

  public updateSession = async (sessionParams: { chainId?: string; address?: string }) => {
    const { connector, proposal, chainId, address, topic } = this.state;
    const newChainId = sessionParams.chainId || chainId;
    const newAddress = sessionParams.address || address;
    if (connector) {
      const namespaces: SessionTypes.Namespaces = {};
      Object.keys(proposal.params.requiredNamespaces).forEach((key) => {
        const chains = [`${address.startsWith("0x") ? "eip155" : "polkadot"}:${newChainId}`];
        const accounts: string[] = [];
        chains?.map((chain) => {
          accounts.push(`${chain}:${newAddress}`);
        });
        namespaces[key] = {
          accounts,
          chains,
          methods: proposal.params.requiredNamespaces[key].methods,
          events: proposal.params.requiredNamespaces[key].events,
        };
      });
      connector.update({
        topic,
        namespaces,
      });
    }
    this.setState({
      connector,
      address: newAddress,
      chainId: newChainId,
    });
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
    const checkPass: any = await (isSubstrate ? keyring : ethKeyring).checkPassword(address, pass);
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

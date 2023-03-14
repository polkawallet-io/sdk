import WalletConnect from "@walletconnect/client";
import { DEFAULT_CHAIN_ID, DEFAULT_WALLET_CLIENT } from "./constants";
import { getRpcEngine } from "../engines";
import { notifyWallet } from "./helpers/wallet";

import ethKeyring from "../../eth/keyring";
import { getCachedSession } from "./helpers/utilities";

export interface IAppState {
  loading: boolean;
  connector: WalletConnect | null;
  uri: string;
  peerMeta: {
    description: string;
    url: string;
    icons: string[];
    name: string;
  };
  connected: boolean;
  chainId: number;
  address: string;
  requests: any[];
  results: any[];
}

export const INITIAL_STATE: IAppState = {
  loading: false,
  connector: null,
  uri: "",
  peerMeta: {
    description: "",
    url: "",
    icons: [],
    name: "",
  },
  connected: false,
  chainId: DEFAULT_CHAIN_ID,
  address: "",
  requests: [],
  results: [],
};

class ClientApp {
  public state: IAppState;

  constructor() {
    this.state = {
      ...INITIAL_STATE,
    };
  }

  private setState(data: Partial<IAppState>) {
    this.state = {
      ...this.state,
      ...data,
    };
  }

  public bindedSetState = (newState: Partial<IAppState>) => this.setState(newState);

  public initWalletConnect = async (uri: string, address: string, chainId: number) => {
    if (this.state.connector?.connected) {
      this.killSession();

      setTimeout(() => this.initWalletConnect(uri, address, chainId), 300);
      return;
    }

    this.setState({ loading: true, address, chainId, uri });

    try {
      const connector = new WalletConnect({ uri, clientMeta: DEFAULT_WALLET_CLIENT });

      if (!connector.connected) {
        await connector.createSession({ chainId: Number(chainId) });
      }

      this.setState({
        loading: false,
        connector,
        uri: connector.uri,
      });

      this.subscribeToEvents();
    } catch (error) {
      this.setState({ loading: false });

      throw error;
    }
  };

  public reConnectSession = async (session: any) => {
    const connector = new WalletConnect({ session });

    const { chainId, accounts, peerMeta } = connector;

    this.setState({
      connector,
      address: accounts[0],
      chainId,
      peerMeta,
    });

    this.subscribeToEvents();
  };

  public approveSession = () => {
    // console.log("ACTION", "approveSession");
    const { connector, chainId, address } = this.state;
    if (connector) {
      connector.approveSession({ chainId, accounts: [address] });
    }
    this.setState({ connector });
  };

  public rejectSession = () => {
    // console.log("ACTION", "rejectSession");
    const { connector } = this.state;
    if (connector) {
      connector.rejectSession();
    }
    this.setState({ connector });
  };

  public killSession = () => {
    // console.log("ACTION", "killSession");
    const { connector } = this.state;
    if (connector) {
      connector.killSession();
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
      connector.on("session_request", (error, payload) => {
        // console.log("EVENT", "session_request");

        if (error) {
          throw error;
        }
        // console.log("SESSION_REQUEST", payload.params);
        const { peerMeta } = payload.params[0];
        this.setState({ peerMeta });

        notifyWallet({ event: "session_request", peerMeta });
      });

      connector.on("session_update", (error) => {
        // console.log("EVENT", "session_update");

        if (error) {
          throw error;
        }
      });

      connector.on("call_request", async (error, payload) => {
        // tslint:disable-next-line
        // console.log("EVENT", "call_request", "method", payload.method);
        // console.log("EVENT", "call_request", "params", payload.params);

        if (error) {
          throw error;
        }

        await getRpcEngine().router(payload, this.state, this.bindedSetState);

        const paramsHuman = getRpcEngine().render(payload);
        notifyWallet({ event: "call_request", id: payload.id, params: paramsHuman });
      });

      connector.on("connect", (error, payload) => {
        // console.log("EVENT", "connect");

        if (error) {
          throw error;
        }

        this.setState({ connected: true });

        notifyWallet({ event: "connect", session: getCachedSession() });
      });

      connector.on("disconnect", (error, payload) => {
        // console.log("EVENT", "disconnect");

        if (error) {
          throw error;
        }

        notifyWallet({ event: "disconnect" });

        this.resetApp();
      });
    }
  };

  public updateSession = async (sessionParams: { chainId?: number; address?: string }) => {
    const { connector, chainId, address } = this.state;
    const newChainId = sessionParams.chainId || chainId;
    const newAddress = sessionParams.address || address;
    if (connector) {
      connector.updateSession({
        chainId: newChainId,
        accounts: [newAddress],
      });
    }
    this.setState({
      connector,
      address: newAddress,
      chainId: newChainId,
    });
  };

  public updateChain = async (chainId: number | string) => {
    await this.updateSession({ chainId: Number(chainId) });
  };

  public onURIReceive = async (data: any, address: string, chainId: number) => {
    const uri = typeof data === "string" ? data : "";
    if (uri) {
      await this.initWalletConnect(uri, address, chainId);
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
    const { connector, requests, address } = this.state;

    const payload = requests.find((e) => e.id === id);
    if (!payload) {
      console.error("call request id no match.");

      callback({ error: "call request id no match." });
      return;
    }

    const checkPass = await ethKeyring.checkPassword(address, pass);
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
        connector.rejectRequest({
          id: payload.id,
          error: { message: "Failed or Rejected Request" },
        });
      }
    }

    this.closeRequest(id);
    this.setState({ connector });
  };

  public rejectRequest = async (id: number) => {
    const { connector } = this.state;
    if (connector) {
      connector.rejectRequest({
        id,
        error: { message: "Failed or Rejected Request" },
      });
    }
    await this.closeRequest(id);
    this.setState({ connector });
  };
}

export default ClientApp;

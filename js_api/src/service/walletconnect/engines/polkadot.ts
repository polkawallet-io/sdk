import { IAppState2 } from "../v2/client";
import { IRequestRenderParams, IRpcEngine, IJsonRpcRequest } from "../v1/helpers/types";

import keyring from "../../keyring";

export function formatJsonRpcResult(id: number, result: any) {
  return { id, jsonrpc: "2.0", result };
}
export function formatJsonRpcError(id: number, error: any) {
  return { id, jsonrpc: "2.0", error };
}

export function filterPolkadotRequests(payload: any) {
  return payload.method.startsWith("polkadot_");
}

export async function routePolkadotRequests(payload: IJsonRpcRequest, state: IAppState2, setState: any) {
  if (!state.connector) {
    return;
  }

  const requests = state.requests;
  requests.push(payload);
  setState({ requests });
}

export function renderPolkadotRequests(payload: any): IRequestRenderParams[] {
  let params = [{ label: "Method", value: payload.method }];

  switch (payload.method) {
    case "polkadot_signTransaction":
      params = [
        ...params,
        { label: "Address", value: payload.params.address },
        { label: "Extrinsic", value: payload.params.transactionPayload },
      ];
      break;
    case "polkadot_signMessage":
      params = [...params, { label: "Address", value: payload.params.address }, { label: "Message", value: payload.params.message }];
      break;
    default:
      params = [
        ...params,
        {
          label: "params",
          value: JSON.stringify(payload.params, null, "\t"),
        },
      ];
      break;
  }
  return params;
}

export async function signPolkadotPayload(payload: any, address: string, pass: string) {
  let errorMsg = "";
  let result = null;

  switch (payload.method) {
    case "polkadot_signTransaction":
      if (address === payload.params.address) {
        const res: any = await keyring.signTxAsExtension(pass, payload.params.transactionPayload);
        if (res.error) {
          errorMsg = res.error;
        } else {
          result = res.signature;
        }
      } else {
        errorMsg = "Address requested does not match active account";
      }
      break;
    case "polkadot_signMessage":
      if (address === payload.params.address) {
        const res: any = await keyring.signBytesAsExtension(pass, { address, data: payload.params.message });
        if (res.error) {
          errorMsg = res.error;
        } else {
          result = res.signature;
        }
      } else {
        errorMsg = "Address requested does not match active account";
      }
      break;
    default:
      break;
  }

  if (!result && !errorMsg) {
    errorMsg = "JSON RPC method not supported";
  }

  return { id: payload.id, result, error: errorMsg };
}

export async function signPolkadotRequests(payload: any, state: IAppState2, pass: string, _: any) {
  const { connector, address, chainId } = state;

  let errorMsg = "";
  let result = null;

  if (connector) {
    const res = await signPolkadotPayload(payload, address, pass);
    result = res.result;
    errorMsg = res.error;

    if (result) {
      connector.respond({ topic: state.topic, response: formatJsonRpcResult(payload.id, { signature: result }) });
    } else {
      connector.respond({
        topic: state.topic,
        response: formatJsonRpcError(payload.id, { message: errorMsg }),
      });
    }
  }
  return { result, error: errorMsg };
}

const polkadot: IRpcEngine = {
  filter: filterPolkadotRequests,
  router: routePolkadotRequests,
  render: renderPolkadotRequests,
  signer: signPolkadotRequests,
};

export default polkadot;

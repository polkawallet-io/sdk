import { signingMethods, convertHexToNumber, convertNumberToHex } from "@walletconnect/utils";
import { IJsonRpcRequest } from "@walletconnect/types";

import { IAppState } from "../client";
import { apiGetCustomRequest } from "../helpers/api";
import { convertHexToUtf8IfPossible } from "../helpers/utilities";
import { IRequestRenderParams, IRpcEngine } from "../helpers/types";

import ethKeyring from "../../../eth/keyring";

export function filterEthereumRequests(payload: any) {
  return (
    payload.method.startsWith("eth_") ||
    payload.method.startsWith("net_") ||
    payload.method.startsWith("shh_") ||
    payload.method.startsWith("personal_") ||
    payload.method.startsWith("wallet_")
  );
}

export async function routeEthereumRequests(payload: IJsonRpcRequest, state: IAppState, setState: any) {
  if (!state.connector) {
    return;
  }

  // estimate gas limit if we send the tx
  if (payload.method === "eth_sendTransaction") {
    payload.params[0].gas = convertNumberToHex(await ethKeyring.estimateTxGas(payload.params[0]));
    payload.params[0].gasLimit = payload.params[0].gas;
  }

  const { chainId, connector } = state;
  if (!signingMethods.includes(payload.method)) {
    try {
      const result = await apiGetCustomRequest(chainId, payload);
      connector.approveRequest({
        id: payload.id,
        result,
      });
    } catch (error) {
      return connector.rejectRequest({
        id: payload.id,
        error: { message: "JSON RPC method not supported" },
      });
    }
  } else {
    const requests = state.requests;
    requests.push(payload);
    await setState({ requests });
  }
}

export function renderEthereumRequests(payload: any): IRequestRenderParams[] {
  let params = [{ label: "Method", value: payload.method }];

  switch (payload.method) {
    case "eth_sendTransaction":
    case "eth_signTransaction":
      params = [
        ...params,
        { label: "From", value: payload.params[0].from },
        { label: "To", value: payload.params[0].to },
        {
          label: "Gas Limit",
          value: payload.params[0].gas
            ? convertHexToNumber(payload.params[0].gas)
            : payload.params[0].gasLimit
            ? convertHexToNumber(payload.params[0].gasLimit)
            : "",
        },
        {
          label: "Gas Price",
          value: convertHexToNumber(payload.params[0].gasPrice ?? "0x0"),
        },
      ];
      if (payload.params[0].nonce !== undefined) {
        params.push({
          label: "Nonce",
          value: convertHexToNumber(payload.params[0].nonce),
        });
      }
      params = [
        ...params,
        {
          label: "Value",
          value: payload.params[0].value ? convertHexToNumber(payload.params[0].value) : "",
        },
        { label: "Data", value: payload.params[0].data },
      ];
      break;

    case "eth_sign":
      params = [...params, { label: "Address", value: payload.params[0] }, { label: "Message", value: payload.params[1] }];
      break;
    case "personal_sign":
      params = [
        ...params,
        { label: "Address", value: payload.params[1] },
        {
          label: "Message",
          value: convertHexToUtf8IfPossible(payload.params[0]),
        },
      ];
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

export async function signEthPayload(payload: any, address: string, pass: string, gasOptions: any) {
  let errorMsg = "";
  let result = null;

  let transaction = null;
  let dataToSign = null;
  let addressRequested = null;

  switch (payload.method) {
    case "eth_sendTransaction":
      transaction = payload.params[0];
      addressRequested = transaction.from;
      if (address.toLowerCase() === addressRequested.toLowerCase()) {
        const res = await ethKeyring.signAndSendTx(transaction, address, pass, gasOptions);
        if (res.error) {
          errorMsg = res.error;
        } else {
          result = res.hash;
        }
      } else {
        errorMsg = "Address requested does not match active account";
      }
      break;
    case "eth_signTransaction":
      transaction = payload.params[0];
      addressRequested = transaction.from;
      if (address.toLowerCase() === addressRequested.toLowerCase()) {
        const res = await ethKeyring.signTx(transaction, address, pass);
        if (res.error) {
          errorMsg = res.error;
        } else {
          result = res.signed;
        }
      } else {
        errorMsg = "Address requested does not match active account";
      }
      break;
    case "eth_sign":
      dataToSign = payload.params[1];
      addressRequested = payload.params[0];
      if (address.toLowerCase() === addressRequested.toLowerCase()) {
        const res = await ethKeyring.signMessage(dataToSign, address, pass);
        if (res.error) {
          errorMsg = res.error;
        } else {
          result = res.signature;
        }
      } else {
        errorMsg = "Address requested does not match active account";
      }
      break;
    case "personal_sign":
      dataToSign = payload.params[0];
      addressRequested = payload.params[1];
      if (address.toLowerCase() === addressRequested.toLowerCase()) {
        const res = await ethKeyring.signMessage(dataToSign, address, pass);
        if (res.error) {
          errorMsg = res.error;
        } else {
          result = res.signature;
        }
      } else {
        errorMsg = "Address requested does not match active account";
      }
      break;
    case "eth_signTypedData":
    case "eth_signTypedData_v4":
      const isV4 = typeof payload.params[0] === "string" && payload.params[0].substring(0, 2) === "0x";
      dataToSign = payload.params[isV4 ? 1 : 0];
      addressRequested = payload.params[isV4 ? 0 : 1];
      if (address.toLowerCase() === addressRequested.toLowerCase()) {
        const res = await ethKeyring.signTypedData(dataToSign, address, pass);
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

export async function signEthereumRequests(payload: any, state: IAppState, setState: any, pass: string, gasOptions: any) {
  const { connector, address, chainId } = state;

  let errorMsg = "";
  let result = null;

  if (connector) {
    const res = await signEthPayload(payload, address, pass, gasOptions);
    result = res.result;
    errorMsg = res.error;

    if (result) {
      connector.approveRequest({
        id: payload.id,
        result,
      });
    } else {
      connector.rejectRequest({
        id: payload.id,
        error: { message: errorMsg },
      });
    }
  }
  return { result, error: errorMsg };
}

const ethereum: IRpcEngine = {
  filter: filterEthereumRequests,
  router: routeEthereumRequests,
  render: renderEthereumRequests,
  signer: signEthereumRequests,
};

export default ethereum;

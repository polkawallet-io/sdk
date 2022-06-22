interface JsonRpcResult {
  id: number;
  jsonrpc: string;
  result: any;
}

export function formatJsonRpcResult<T = any>(id: number, result: T): JsonRpcResult {
  return {
    id,
    jsonrpc: "2.0",
    result,
  };
}

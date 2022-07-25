import bridge from "./service/bridge";

// console.log will send message to MsgChannel to App
function send(path: string, data: any) {
  console.log(JSON.stringify({ path, data }));
}
send("log", "bridge js loaded");
(<any>window).send = send;

(<any>window).bridge = bridge;
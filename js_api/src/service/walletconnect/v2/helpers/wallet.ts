export const notifyWallet = (data: any) => {
  (<any>window).send("wallet_connect_message_v2", data);
};

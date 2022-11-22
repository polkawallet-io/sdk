export const notifyWallet = (data: any) => {
  (<any>window).send("wallet_connect_message", data);
};

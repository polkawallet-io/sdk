export const notifyWallet = (data: any) => {
  console.log("send wc message to wallet", data);

  (<any>window).send("wallet_connect_message", data);
};

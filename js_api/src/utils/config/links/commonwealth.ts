const HASH_PATHS = ["proposal/councilmotion"];

export default {
  chains: {
    Edgeware: "edgeware",
    Kusama: "kusama",
    "Kusama CC3": "kusama",
  },
  create: (chain: string, path: string, data: any, hash: string) =>
    `https://commonwealth.im/${chain}/${path}/${
      HASH_PATHS.includes(path) ? hash || "" : data.toString()
    }`,
  isActive: true,
  paths: {
    council: "proposal/councilmotion",
    proposal: "proposal/democracyproposal",
    referendum: "proposal/referendum",
    treasury: "proposal/treasuryproposal",
  },
  url: "https://commonwealth.im/",
};

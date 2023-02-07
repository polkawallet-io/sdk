import Commonwealth from "./commonwealth";
import Polkascan from "./polkascan";
import { PolkassemblyIo, PolkassemblyNetwork } from "./polkassembly";
import Subscan from "./subscan";
import SubSquare from "./subsquare";

const externals = {
  Commonwealth,
  Polkascan,
  Polkassembly: PolkassemblyIo,
  PolkassemblyNetwork,
  Subscan,
  SubSquare,
};

export default externals;

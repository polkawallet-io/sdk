import { ApiPromise } from "@polkadot/api";
import { DeriveCollectiveProposal, DeriveReferendumExt, DeriveCouncilVotes } from "@polkadot/api-derive/types";
import { SubmittableExtrinsic } from "@polkadot/api/types";
import { getTypeDef, Option, Bytes } from "@polkadot/types";
import { OpenTip, AccountId } from "@polkadot/types/interfaces";
import { formatBalance, stringToU8a, BN_ZERO, hexToString } from "@polkadot/util";
import BN from "bn.js";

import { approxChanges } from "../utils/referendumApproxChanges";

function _extractMetaData(value: any) {
  const params = value.meta.args.map(({ name, type }) => ({
    name: name.toString(),
    type: getTypeDef(type.toString()),
  }));
  const values = value.args.map((value) => ({
    isValid: true,
    value,
  }));
  const hash = value.hash.toHex();

  return { hash, params, values };
}

function _transfromProposalMeta(proposal: any): {} {
  const { meta } = proposal.registry.findMetaCall(proposal.callIndex);
  const docs = meta.documentation || meta.docs;
  let doc = "";
  for (let i = 0; i < docs.length; i++) {
    if (docs[i].length) {
      doc += docs[i];
    } else {
      break;
    }
  }
  const json = proposal.toHuman();
  let args: string[] = Object.values(json.args);
  if (json.method == "setCode") {
    args = [json.args.code.substring(0, 64)];
  }
  return {
    callIndex: proposal.toJSON().callIndex,
    method: json.method,
    section: json.section,
    args,
    meta: {
      ...meta.toJSON(),
      documentation: doc,
    },
  };
}

/**
 * Query active referendums and it's voting info of an address.
 */
async function fetchReferendums(api: ApiPromise, address: string) {
  const referendums: DeriveReferendumExt[] = await api.derive.democracy.referendums();
  const sqrtElectorate = await api.derive.democracy.sqrtElectorate();
  const details = referendums.map(({ image, imageHash, status, votedAye, votedNay, votedTotal, votes }) => {
    let proposalMeta: any = {};
    let parsedMeta: any = {};
    if (image && image.proposal) {
      proposalMeta = _extractMetaData(image.proposal);
      parsedMeta = _transfromProposalMeta(image.proposal);
      image.proposal = {
        ...image.proposal.toHuman(),
        args: parsedMeta.args,
      } as any;
    }

    const changes = approxChanges(status.threshold, sqrtElectorate, {
      votedAye,
      votedNay,
      votedTotal,
    });

    const voted = votes.find((i) => i.accountId.toString() == address);
    const userVoted = voted
      ? {
          balance: voted.balance,
          vote: voted.vote.toHuman(),
        }
      : null;
    return {
      ...proposalMeta,
      ...parsedMeta,
      title: `${parsedMeta.section}.${parsedMeta.method}`,
      content: parsedMeta.meta?.documentation,
      imageHash: imageHash.toHuman(),
      changes: {
        changeAye: changes.changeAye.toString(),
        changeNay: changes.changeNay.toString(),
      },
      userVoted,
    };
  });
  return { referendums, details };
}

const CONVICTIONS = [1, 2, 4, 8, 16, 32].map((lock, index) => [index + 1, lock]);
const SEC_DAY = 60 * 60 * 24;
// REMOVE once Polkadot is upgraded with the correct conviction
const PERIODS = {
  "0x91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3": new BN(403200),
};
/**
 * Query ReferendumVoteConvictions.
 */
async function getReferendumVoteConvictions(api: ApiPromise) {
  const enact =
    (((((<any>PERIODS)[api.genesisHash.toHex()] || api.consts.democracy.enactmentPeriod).toNumber() *
      api.consts.timestamp.minimumPeriod.toNumber()) /
      1000) *
      2) /
    SEC_DAY;
  const res = CONVICTIONS.map(([value, lock]) => ({
    lock,
    period: (enact * lock).toFixed(2),
    value,
  }));
  return res;
}

/**
 * Query active Proposals.
 */
async function fetchProposals(api: ApiPromise) {
  const proposals = await api.derive.democracy.proposals();
  return proposals.map((e) => {
    if (e.image && e.image.proposal) {
      e.image.proposal = _transfromProposalMeta(e.image.proposal) as any;
    }
    return e;
  });
}

/**
 * Query votes of council members and candidates.
 */
async function fetchCouncilVotes(api: ApiPromise) {
  const councilVotes: DeriveCouncilVotes = await api.derive.council.votes();
  return councilVotes.reduce((result, [voter, { stake, votes }]) => {
    const res: any = { ...result };
    votes.forEach((candidate) => {
      const address = candidate.toString();
      if (!res[address]) {
        res[address] = {};
      }
      (<any>res[address])[voter.toString()] = stake;
    });
    return res;
  }, {});
}

const TREASURY_ACCOUNT = stringToU8a("modlpy/trsry".padEnd(32, "\0"));
/**
 * Query overview of treasury and spend proposals.
 */
async function getTreasuryOverview(api: ApiPromise) {
  const proposals = await api.derive.treasury.proposals();
  const balance = await api.derive.balances.account(TREASURY_ACCOUNT as AccountId);
  const res: any = {
    ...proposals,
  };
  res["balance"] = formatBalance(balance.freeBalance, {
    forceUnit: "-",
    withSi: false,
  }).split(".")[0];
  res.proposals.forEach((e: any) => {
    if (e.council.length) {
      e.council = e.council.map((i: any) => ({
        ...i,
        proposal: _transfromProposalMeta(i.proposal),
      }));
    }
  });
  return res;
}

/**
 * Query tips of treasury.
 */
async function getTreasuryTips(api: ApiPromise) {
  const tipKeys = await (api.query.tips || api.query.treasury).tips.keys();
  const tipHashes = tipKeys.map((key) => key.args[0].toHex());
  const optTips = (await (api.query.tips || api.query.treasury).tips.multi(tipHashes)) as Option<OpenTip>[];
  const tips = optTips
    .map((opt, index) => [tipHashes[index], opt.unwrapOr(null)])
    .filter((val) => !!val[1])
    .sort((a: any[], b: any[]) => a[1].closes.unwrapOr(BN_ZERO).cmp(b[1].closes.unwrapOr(BN_ZERO)));
  return Promise.all(
    tips.map(async (tip: any[]) => {
      const detail = tip[1].toJSON();
      const reason = (await (api.query.tips || api.query.treasury).reasons(detail.reason)) as Option<Bytes>;
      const tips = detail.tips.map((e: any) => ({
        address: e[0],
        value: e[1],
      }));
      return {
        hash: tip[0],
        ...detail,
        reason: reason.isSome ? hexToString(reason.unwrap().toHex()) : null,
        tips,
      };
    })
  );
}

/**
 * make an extrinsic of treasury proposal submission for council member.
 */
async function makeTreasuryProposalSubmission(api: ApiPromise, id: any, isReject: boolean): Promise<SubmittableExtrinsic<"promise">> {
  const members = await (api.query.electionsPhragmen || api.query.elections || api.query.phragmenElection).members<any[]>();
  const councilThreshold = Math.ceil(members.length * 0.6);
  const proposal = isReject ? api.tx.treasury.rejectProposal(id) : api.tx.treasury.approveProposal(id);
  return api.tx.council.propose(councilThreshold, proposal, proposal.length);
}

/**
 * Query motions of council.
 */
async function getCouncilMotions(api: ApiPromise) {
  const motions: DeriveCollectiveProposal[] = await api.derive.council.proposals();
  const res: any[] = [];
  motions.forEach((e) => {
    res.push({
      ...e,
      proposal: _transfromProposalMeta(e.proposal),
    });
  });
  return res;
}

async function getDemocracyUnlocks(api: ApiPromise, address: string) {
  const locks = await Promise.all([api.derive.chain.bestNumber(), api.derive.democracy.locks(address)]);
  return locks[1].filter(({ isFinished, unlockAt }) => isFinished && locks[0].gt(unlockAt)).map(({ referendumId }) => referendumId);
}

export default {
  fetchReferendums,
  getReferendumVoteConvictions,
  fetchProposals,
  fetchCouncilVotes,
  getCouncilMotions,
  getTreasuryOverview,
  getTreasuryTips,
  makeTreasuryProposalSubmission,
  getDemocracyUnlocks,
};

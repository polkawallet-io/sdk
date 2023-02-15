import { ApiPromise } from "@polkadot/api";
import { Hash, Call } from "@polkadot/types/interfaces";
import { HexString } from "@polkadot/util/types";
import { Registry } from "@polkadot/types/types";

import { Option, Bytes } from "@polkadot/types";
import {
  BN_ZERO,
  BN_ONE,
  BN_BILLION,
  BN,
  bnMax,
  bnMin,
  stringPascalCase,
  formatNumber,
  isString,
  isU8a,
  u8aToHex,
  objectSpread,
} from "@polkadot/util";

function checkGovExist(api: ApiPromise, version: number) {
  if (version === 1) {
    return !!api.tx.democracy?.propose;
  }
  return !!api.tx.referenda?.submit && !!api.tx.convictionVoting?.vote && !!api.consts.referenda?.tracks;
}

function _isConvictionTally(tally: any) {
  return !!tally.support && !tally.bareAyes;
}

function _isConvictionVote(info: any) {
  return info.isOngoing && _isConvictionTally(info.asOngoing.tally);
}

function _getTrackName(trackId: BN, name: any): string {
  return `${formatNumber(trackId)} / ${name
    .replace(/_/g, " ")
    .split(" ")
    .map(stringPascalCase)
    .join(" ")}`;
}

export function _curveDelay(curve: any, input: BN, div: BN): BN {
  // if divisor is zero, we return the max
  if (div.isZero()) {
    return BN_BILLION;
  }

  const y = input.mul(BN_BILLION).div(div);

  if (curve.isLinearDecreasing) {
    const { ceil, floor, length } = curve.asLinearDecreasing;

    // if y < *floor {
    //   Perbill::one()
    // } else if y > *ceil {
    //   Perbill::zero()
    // } else {
    //   (*ceil - y).saturating_div(*ceil - *floor, Up).saturating_mul(*length)
    // }
    return y.lt(floor)
      ? BN_BILLION
      : y.gt(ceil)
      ? BN_ZERO
      : bnMin(
          BN_BILLION,
          bnMax(
            BN_ZERO,
            ceil
              .sub(y)
              .mul(length)
              .div(ceil.sub(floor))
          )
        );
  } else if (curve.isSteppedDecreasing) {
    const { begin, end, period, step } = curve.asSteppedDecreasing;

    // if y < *end {
    //   Perbill::one()
    // } else {
    //   period.int_mul((*begin - y.min(*begin) + step.less_epsilon()).int_div(*step))
    // }
    return y.lt(end)
      ? BN_BILLION
      : bnMin(BN_BILLION, bnMax(BN_ZERO, period.mul(begin.sub(bnMin(y, begin)).add(step.isZero() ? step : step.sub(BN_ONE))).div(step)));
  } else if (curve.asReciprocal) {
    const { factor, xOffset, yOffset } = curve.asReciprocal;

    // let y = FixedI64::from(y);
    // let maybe_term = factor.checked_rounding_div(y - *y_offset, High);
    // maybe_term
    //   .and_then(|term| (term - *x_offset).try_into_perthing().ok())
    //   .unwrap_or_else(Perbill::one)
    return bnMin(
      BN_BILLION,
      bnMax(
        BN_ZERO,
        factor
          .mul(BN_BILLION)
          .div(y.sub(yOffset))
          .sub(xOffset)
      )
    );
  }

  throw new Error(`Unknown curve found ${curve.type}`);
}

function _calcDecidingEnd(totalEligible: BN, tally: any, { decisionPeriod, minApproval, minSupport }: any, since: BN): BN | undefined {
  const support = _isConvictionTally(tally) ? tally.support : tally.bareAyes;

  return since.add(
    decisionPeriod
      .mul(bnMax(_curveDelay(minApproval, tally.ayes, tally.ayes.add(tally.nays)), _curveDelay(minSupport, support, totalEligible)))
      .div(BN_BILLION)
  );
}

interface PreimageDeposit {
  amount: BN;
  who: string;
}

interface PreimageStatus {
  count: number;
  deposit?: PreimageDeposit;
  isCompleted: boolean;
  isHashParam: boolean;
  proposalHash: HexString;
  proposalLength?: BN;
  registry: Registry;
  status: any;
}

interface PreimageBytes {
  proposal?: Call | null;
  proposalError?: string | null;
  proposalWarning?: string | null;
}

interface Preimage extends PreimageBytes, PreimageStatus {
  // just the interfaces above
}

interface StatusParams {
  inlineData?: Uint8Array;
  paramsStatus?: [HexString];
  proposalHash?: HexString;
  resultPreimageHash?: PreimageStatus;
}

interface BytesParams {
  paramsBytes?: any;
  resultPreimageFor?: PreimageStatus;
}

type Result = "unknown" | "hash" | "hashAndLen";

/**
 * @internal Determine if we are working with current generation (H256,u32)
 * or previous generation H256 params to the preimageFor storage entry
 */
function _getParamType(api: ApiPromise): Result {
  if (api.query.preimage && api.query.preimage.preimageFor && api.query.preimage.preimageFor.creator.meta.type.isMap) {
    const { type } = api.registry.lookup.getTypeDef(api.query.preimage.preimageFor.creator.meta.type.asMap.key);

    if (type === "H256") {
      return "hash";
    } else if (type === "(H256,u32)") {
      return "hashAndLen";
    } else {
      // we are clueless :()
    }
  }

  return "unknown";
}

/** @internal Unwraps a passed preimage hash into components */
function _getPreimageHash(api: ApiPromise, hashOrBounded: any): StatusParams {
  let proposalHash: any;
  let inlineData: Uint8Array | undefined;

  if (isString(hashOrBounded)) {
    proposalHash = hashOrBounded;
  } else if (isU8a(hashOrBounded)) {
    proposalHash = (hashOrBounded as any).toHex();
  } else {
    const bounded = hashOrBounded;

    if (bounded.isInline) {
      inlineData = bounded.asInline.toU8a(true);
      proposalHash = u8aToHex(api.registry.hash(inlineData));
    } else if (hashOrBounded.isLegacy) {
      proposalHash = hashOrBounded.asLegacy.hash_.toHex();
    } else if (hashOrBounded.isLookup) {
      proposalHash = hashOrBounded.asLookup.hash_.toHex();
    } else {
      console.error(`Unhandled FrameSupportPreimagesBounded type ${hashOrBounded.type}`);
    }
  }

  return {
    inlineData,
    paramsStatus: proposalHash && [proposalHash],
    proposalHash,
    resultPreimageHash: proposalHash && {
      count: 0,
      isCompleted: false,
      isHashParam: _getParamType(api) === "hash",
      proposalHash,
      proposalLength: inlineData && new BN(inlineData.length),
      registry: api.registry,
      status: null,
    },
  };
}

function _unwrapDeposit(value: any | Option<any>) {
  return value instanceof Option ? value.unwrapOr(null) : value;
}

function _creatPreimageResult(interimResult: PreimageStatus, optBytes: Option<Bytes> | Uint8Array): Preimage {
  const callData = isU8a(optBytes) ? optBytes : optBytes.unwrapOr(null);
  let proposal: Call | null = null;
  let proposalError: string | null = null;
  let proposalWarning: string | null = null;
  let proposalLength: BN | undefined;

  if (callData) {
    try {
      proposal = interimResult.registry.createType("Call", callData);

      const callLength = proposal.encodedLength;

      if (interimResult.proposalLength) {
        const storeLength = interimResult.proposalLength.toNumber();

        if (callLength !== storeLength) {
          proposalWarning = `Decoded call length does not match on-chain stored preimage length (${formatNumber(
            callLength
          )} bytes vs ${formatNumber(storeLength)} bytes)`;
        }
      } else {
        // for the old style, we set the actual length
        proposalLength = new BN(callLength);
      }
    } catch (error) {
      console.error(error);

      proposalError = "Unable to decode preimage bytes into a valid Call";
    }
  } else {
    proposalWarning = "No preimage bytes found";
  }

  return objectSpread<Preimage>({}, interimResult, {
    isCompleted: true,
    proposal,
    proposalError,
    proposalLength: proposalLength || interimResult.proposalLength,
    proposalWarning,
  });
}

function _convertDeposit(deposit?: any): PreimageDeposit | undefined {
  return deposit
    ? {
        amount: deposit[1],
        who: deposit[0].toString(),
      }
    : undefined;
}

function _getBytesParams(interimResult: PreimageStatus, optStatus: Option<any>): BytesParams {
  const result = objectSpread<PreimageStatus>({}, interimResult, {
    status: optStatus.unwrapOr(null),
  });

  if (result.status) {
    if (result.status.isRequested) {
      const asRequested = result.status.asRequested;

      if (asRequested instanceof Option) {
        // FIXME Cannot recall how to deal with these
        // (unlike Unrequested below, didn't have an example)
      } else {
        const { count, deposit, len } = asRequested;

        result.count = count.toNumber();
        result.deposit = _convertDeposit(deposit.unwrapOr(null));
        result.proposalLength = len.unwrapOr(BN_ZERO);
      }
    } else if (result.status.isUnrequested) {
      const asUnrequested = result.status.asUnrequested;

      if (asUnrequested instanceof Option) {
        result.deposit = _convertDeposit(
          // old-style conversion
          (asUnrequested as any).unwrapOr(null)
        );
      } else {
        const { deposit, len } = result.status.asUnrequested;

        result.deposit = _convertDeposit(deposit);
        result.proposalLength = len;
      }
    } else {
      console.error(`Unhandled PalletPreimageRequestStatus type: ${result.status.type}`);
    }
  }

  return {
    paramsBytes: result.isHashParam ? [result.proposalHash] : [[result.proposalHash, result.proposalLength || BN_ZERO]],
    resultPreimageFor: result,
  };
}

async function _parsePreimage(api: ApiPromise, preimageHash?: StatusParams): Promise<Preimage | undefined> {
  const optStatus =
    !preimageHash.inlineData && preimageHash.paramsStatus && (await api.query.preimage?.statusFor(preimageHash.paramsStatus[0]));

  // from the retrieved status (if any), get the on-chain stored bytes
  const bytesParams =
    preimageHash.resultPreimageHash && optStatus ? _getBytesParams(preimageHash.resultPreimageHash, optStatus as any) : {};

  const optBytes = bytesParams.paramsBytes && (await api.query.preimage?.preimageFor(...bytesParams.paramsBytes));

  // extract all the preimage info we have retrieved
  return bytesParams.resultPreimageFor
    ? optBytes
      ? _creatPreimageResult(bytesParams.resultPreimageFor, optBytes as any)
      : bytesParams.resultPreimageFor
    : preimageHash.resultPreimageHash
    ? preimageHash.inlineData
      ? _creatPreimageResult(preimageHash.resultPreimageHash, preimageHash.inlineData)
      : preimageHash.resultPreimageHash
    : undefined;
}

async function _expandOngoing(api: ApiPromise, info: any, track?: any) {
  const ongoing = info.asOngoing;
  const proposalHash = _getPreimageHash(api, ongoing.proposal || ((ongoing as unknown) as { proposalHash: Hash }).proposalHash);
  const proposal = await _parsePreimage(api, proposalHash);
  let prepareEnd: BN | null = null;
  let decideEnd: BN | null = null;
  let confirmEnd: BN | null = null;

  if (track) {
    const { deciding, submitted } = ongoing;

    if (deciding.isSome) {
      const { confirming, since } = deciding.unwrap();

      if (confirming.isSome) {
        // we are confirming with the specific end block
        confirmEnd = confirming.unwrap();
      } else {
        // we are still deciding, start + length
        decideEnd = since.add(track.decisionPeriod);
      }
    } else {
      // we are still preparing, start + length
      prepareEnd = submitted.add(track.preparePeriod);
    }
  }

  return {
    decisionDeposit: _unwrapDeposit(ongoing.decisionDeposit)?.toJSON(),
    confirmEnd: confirmEnd?.toString(),
    decideEnd: decideEnd?.toString(),
    periodEnd: (confirmEnd || decideEnd || prepareEnd).toString(),
    prepareEnd: prepareEnd?.toString(),
    callMethod: `${proposal.proposal?.section}.${proposal.proposal?.method}`,
    callDocs: proposal.proposal?.meta && proposal.proposal.meta.docs?.toJSON()[0],
    proposalHash: proposalHash.proposalHash,
    submissionDeposit: _unwrapDeposit(ongoing.submissionDeposit)?.toJSON(),
    tally: ongoing.tally,
    tallyTotal: ongoing.tally.ayes.add(ongoing.tally.nays),
  };
}

function _sortOngoing(a: any, b: any): number {
  const ao = a.info.asOngoing;
  const bo = b.info.asOngoing;

  return (
    ao.track.cmp(bo.track) ||
    (ao.deciding.isSome === bo.deciding.isSome
      ? ao.deciding.isSome
        ? a.info.asOngoing.deciding.unwrap().since.cmp(b.info.asOngoing.deciding.unwrap().since)
        : 0
      : ao.deciding.isSome
      ? -1
      : 1)
  );
}

function _sortReferenda(a: any, b: any): number {
  return (
    (a.info.isOngoing === b.info.isOngoing ? (a.info.isOngoing ? _sortOngoing(a, b) : 0) : a.info.isOngoing ? -1 : 1) || b.id.cmp(a.id)
  );
}

function _sortGroups(a: any, b: any): number {
  return a.trackId && b.trackId ? a.trackId.cmp(b.trackId) : a.trackId ? -1 : 1;
}

async function _group(api: ApiPromise, tracks: any[], totalIssuance?: BN, referenda?: any[]) {
  if (!referenda || !totalIssuance) {
    // return an empty group when we have no referenda
    return [{ key: "empty" }];
  } else if (!tracks) {
    // if we have no tracks, we just return the referenda sorted
    return [{ key: "referenda", referenda: referenda.sort(_sortReferenda) }];
  }

  const grouped: any[] = [];
  const other: any = { key: "referenda", referenda: [] };

  // sort the referenda by track inside groups
  for (let i = 0; i < referenda.length; i++) {
    const ref = referenda[i];

    // only ongoing have tracks
    const trackInfo = ref.info.isOngoing ? tracks.find(({ id }) => id.eq(ref.info.asOngoing.track)) : undefined;

    if (trackInfo) {
      ref.trackGraph = trackInfo.graph;
      ref.trackId = trackInfo.id;
      ref.track = trackInfo.info;

      if (ref.isConvictionVote && ref.info.isOngoing) {
        const { deciding, tally } = ref.info.asOngoing;

        if (deciding.isSome) {
          const { since } = deciding.unwrap();

          ref.decidingEnd = _calcDecidingEnd(totalIssuance, tally, trackInfo.info, since);
        }
      }

      ref.expanded = await _expandOngoing(api, ref.info, ref.track);

      const group = grouped.find(({ track }) => ref.track === track);

      if (!group) {
        // we don't have a group as of yet, create one
        grouped.push({
          key: `track:${ref.trackId.toString()}`,
          referenda: [ref],
          track: ref.track,
          trackId: ref.trackId,
          trackName: _getTrackName(ref.trackId, ref.track.name),
        });
      } else {
        // existing group, just add the referendum
        group.referenda.push(ref);
      }
    } else {
      // if we have no track, we just add it to "other"
      other.referenda.push(ref);
    }
  }

  // if we do have items in "other", we add it (or if none, then empty other)
  if ((other.referenda && other.referenda.length !== 0) || !grouped.length) {
    grouped.push(other);
  }

  // sort referenda per group
  for (let i = 0; i < grouped.length; i++) {
    grouped[i].referenda.sort(_sortReferenda);
  }

  // sort all groups
  return grouped.sort(_sortGroups);
}

/**
 * v2 gov
 * Query active referendums.
 */
async function queryReferendums(api: ApiPromise, address: string) {
  const totalIssuance = await api.query.balances.totalIssuance();
  const referendumKeys = await api.query.referenda.referendumInfoFor.keys();
  const tracks = (api.consts["referenda"].tracks as any).map(([id, info]) => ({ id, info }));
  const ids = referendumKeys.map(({ args: [id] }) => id);
  const referendums = await api.query.referenda.referendumInfoFor.multi(ids);
  const referenda = (referendums as any)
    .map((o, i) => (o.isSome ? [ids[i], o.unwrap()] : null))
    .filter((r) => !!r)
    .map(([id, info]) => ({
      id,
      info,
      isConvictionVote: _isConvictionVote(info),
      key: id.toString(),
    }));
  const groups = await _group(api, tracks, totalIssuance, referenda);

  const userVoted = await api.query.convictionVoting.votingFor.entries(address);
  const bestNumber = await api.derive.chain.bestNumber();
  const userVotes = [];
  userVoted.forEach((e) => {
    const trackId = e[0].args[1].toString();
    const votes = e[1].toHuman()["Casting"]["votes"];

    groups.forEach((g) => {
      const trackKey = g["key"];
      votes.forEach((vote) => {
        const referendum = g["referenda"].find((r) => r.key === vote[0].toString());
        if (!referendum) return;

        if (trackKey === "referenda") {
          const period = (api.consts.convictionVoting.voteLockingPeriod as any).toNumber();
          const info = referendum.info.toJSON();
          let endBlock = Object.values(info)[0][0];
          if (vote[1]["Standard"]) {
            if (vote[1]["Standard"]["vote"]["conviction"] != "None") {
              const con = parseInt(vote[1]["Standard"]["vote"]["conviction"].substring(6, 7));
              endBlock += con * period;
            }
          } else {
            endBlock += period;
          }
          userVotes.push({
            trackId,
            key: vote[0].toString(),
            vote: vote[1],
            isEnded: true,
            redeemable: bestNumber > endBlock,
            status: Object.keys(info)[0],
            endBlock,
          });
        } else {
          userVotes.push({
            trackId,
            key: vote[0].toString(),
            vote: vote[1],
            isEnded: false,
            status: referendum.expanded.confirmEnd ? "confirming" : referendum.expanded.decideEnd ? "deciding" : "preparing",
            endBlock: referendum.expanded.periodEnd,
          });
        }
      });
    });
  });

  return { ongoing: groups.filter((g) => g["key"] !== "referenda"), userVotes };
}

const CONVICTIONS = [1, 2, 4, 8, 16, 32].map((lock, index) => [index + 1, lock]);
const SEC_DAY = 60 * 60 * 24;
/**
 * Query ReferendumVoteConvictions.
 */
async function getReferendumVoteConvictions(api: ApiPromise) {
  const enact =
    ((((api.consts.convictionVoting.voteLockingPeriod as any).toNumber() * api.consts.timestamp.minimumPeriod.toNumber()) / 1000) * 2) /
    SEC_DAY;
  const res = CONVICTIONS.map(([value, lock]) => ({
    lock,
    period: (enact * lock).toFixed(2),
    value,
  }));
  return res;
}

export default {
  checkGovExist,
  // gov v2
  queryReferendums,
  getReferendumVoteConvictions,
};

import { ApiPromise } from "@polkadot/api";
import {
  DeriveStakerReward,
  DeriveStakingElected,
  DeriveSessionInfo,
  DeriveStakingWaiting
} from "@polkadot/api-derive/types";
import type { Option, StorageKey } from '@polkadot/types';
import { u8aConcat, u8aToHex, BN_ZERO, BN_ONE, formatBalance, isFunction, arrayFlatten } from '@polkadot/util';
import { AccountId, Nominations, EraIndex } from "@polkadot/types/interfaces";
import BN from "bn.js";

import { getInflationParams, Inflation } from './inflation';

const divisor = new BN("1".padEnd(12 + 1, "0"));

function _balanceToNumber(amount: BN) {
  return (
    amount
      .muln(1000)
      .div(divisor)
      .toNumber() / 1000
  );
}

function _extractRewards(
  erasRewards: any[],
  ownSlashes: any[],
  allPoints: any[]
) {
  const labels = [];
  const slashSet = [];
  const rewardSet = [];
  const avgSet = [];
  let avgCount = 0;
  let total = 0;

  erasRewards.forEach(({ era, eraReward }) => {
    const points = allPoints.find((points) => points.era.eq(era));
    const slashed = ownSlashes.find((slash) => slash.era.eq(era));
    const reward = points?.eraPoints.gtn(0)
      ? _balanceToNumber(points.points.mul(eraReward).div(points.eraPoints))
      : 0;
    const slash = slashed ? _balanceToNumber(slashed.total) : 0;

    total += reward;

    if (reward > 0) {
      avgCount++;
    }

    labels.push(era.toHuman());
    rewardSet.push(reward);
    avgSet.push((avgCount ? Math.ceil((total * 100) / avgCount) : 0) / 100);
    slashSet.push(slash);
  });

  return {
    chart: [slashSet, rewardSet, avgSet],
    labels,
  };
}

function _extractPoints(points: any[]) {
  const labels = [];
  const avgSet = [];
  const idxSet = [];
  let avgCount = 0;
  let total = 0;

  points.forEach(({ era, points }) => {
    total += points.toNumber();
    labels.push(era.toHuman());

    if (points.gtn(0)) {
      avgCount++;
    }

    avgSet.push((avgCount ? Math.ceil((total * 100) / avgCount) : 0) / 100);
    idxSet.push(points);
  });

  return {
    chart: [idxSet, avgSet],
    labels,
  };
}
function _extractStake(exposures: any[]) {
  const labels = [];
  const cliSet = [];
  const expSet = [];
  const avgSet = [];
  let avgCount = 0;
  let total = 0;

  exposures.forEach(({ clipped, era, exposure }) => {
    const cli = _balanceToNumber(clipped.total.unwrap());
    const exp = _balanceToNumber(exposure.total.unwrap());

    total += cli;

    if (cli > 0) {
      avgCount++;
    }

    avgSet.push((avgCount ? Math.ceil((total * 100) / avgCount) : 0) / 100);
    labels.push(era.toHuman());
    cliSet.push(cli);
    expSet.push(exp);
  });

  return {
    chart: [cliSet, expSet, avgSet],
    labels,
  };
}

/**
 * Query ValidatorRewardsData for validator charts.
 */
async function loadValidatorRewardsData(api: ApiPromise, validatorId: string) {
  const ownSlashes = await api.derive.staking.ownSlashes(validatorId, true);
  const erasRewards = await api.derive.staking.erasRewards();
  const stakerPoints = await api.derive.staking.stakerPoints(validatorId, true);
  const ownExposure = await api.derive.staking.ownExposures(validatorId, true);

  const points = _extractPoints(stakerPoints);
  const rewards = _extractRewards(erasRewards, ownSlashes, stakerPoints);
  const stakes = _extractStake(ownExposure);
  return { points, rewards, stakes };
}

function _getRewards(stashIds: string[], available: any) {
  const allRewards = {};

  stashIds.forEach((stashId, index) => {
    allRewards[stashId] = available[index].filter(
      ({ eraReward }) => !eraReward.isZero()
    );
  });

  return {
    allRewards,
    rewardCount: Object.values(allRewards).filter(
      (rewards: any) => rewards.length !== 0
    ).length,
  };
}

function _groupByValidator(allRewards: Record<string, DeriveStakerReward[]>, stakerPayoutsAfter: BN) {
  return Object.entries(allRewards)
    .reduce((grouped, [stashId, rewards]) => {
      rewards
        .filter(({ era }) => era.gte(stakerPayoutsAfter))
        .forEach((reward) => {
          Object.entries(reward.validators).forEach(
            ([validatorId, { value }]) => {
              const entry = grouped.find(
                (entry) => entry.validatorId === validatorId
              );

              if (entry) {
                const eraEntry = entry.eras.find((entry) =>
                  entry.era.eq(reward.era)
                );

                if (eraEntry) {
                  eraEntry.stashes[stashId] = value;
                } else {
                  entry.eras.push({
                    era: reward.era,
                    stashes: { [stashId]: value },
                  });
                }

                entry.available = entry.available.add(value);
              } else {
                grouped.push({
                  available: value,
                  eras: [
                    {
                      era: reward.era,
                      stashes: { [stashId]: value },
                    },
                  ],
                  validatorId,
                });
              }
            }
          );
        });

      return grouped;
    }, [])
    .sort((a, b) => b.available.cmp(a.available));
}
function _extractStashes(allRewards: Record<string, DeriveStakerReward[]>) {
  return Object.entries(allRewards)
    .map(([stashId, rewards]) => ({
      available: rewards.reduce(
        (result, { validators }) =>
          Object.values(validators).reduce(
            (result, { value }) => result.iadd(value),
            result
          ),
        new BN(0)
      ),
      rewards,
      stashId,
    }))
    .filter(({ available }) => !available.isZero())
    .sort((a, b) => b.available.cmp(a.available));
}
function _getAvailable(allRewards: Record<string, DeriveStakerReward[]>, stakerPayoutsAfter: BN) {
  if (allRewards) {
    const stashes = _extractStashes(allRewards);
    const stashTotal = stashes.length
      ? stashes.reduce((total, { available }) => total.add(available), BN_ZERO)
      : null;

    return {
      stashTotal,
      stashes,
      validators: _groupByValidator(allRewards, stakerPayoutsAfter),
    };
  }

  return {};
}

/**
 * Query staking rewards of an address.
 */
async function loadAccountRewardsData(api: ApiPromise, stashId: string, maxEras: number) {
  // @ts-ignore
  const allEras = await api.derive.staking?.erasHistoric();
  const filteredEras = allEras.slice(-1 * maxEras);

  const stakerRewards = await api.derive.staking.stakerRewardsMultiEras(
    [stashId],
    filteredEras
  );
  // return stakerRewards;
  const { allRewards } = _getRewards([stashId], stakerRewards);
  const stakerPayoutsAfter = isFunction(api.tx.staking.payoutStakers)
    ? new BN(0)
    : new BN("1000000000");
  const res = _getAvailable(allRewards, stakerPayoutsAfter);

  return { available: res.stashTotal, validators: res.validators };
}

interface EraSelection {
  value: number;
  text: number;
  unit: string;
}
const DAY_SECS = new BN(1000 * 60 * 60 * 24);

/**
 * Get era options for query staking rewards.
 */
async function getAccountRewardsEraOptions(api: ApiPromise): Promise<EraSelection[]> {
  const [eraLength, historyDepth] = await Promise.all([
    api.derive.session.eraLength(),
    api.query.staking.historyDepth(),
  ]);

  if (eraLength && historyDepth) {
    const blocksPerDay = DAY_SECS.div(api.consts.babe?.expectedBlockTime || api.consts.timestamp?.minimumPeriod.muln(2) || new BN(6000));
    const maxBlocks = eraLength.mul(historyDepth);
    const eraSelection: EraSelection[] = [];
    let days = 2;

    while (true) {
      const dayBlocks = blocksPerDay.muln(days);

      if (dayBlocks.gte(maxBlocks)) {
        break;
      }

      eraSelection.push({
        text: days,
        unit: "day",
        value: dayBlocks.div(eraLength).toNumber(),
      });

      days = days * 3;
    }

    eraSelection.push({
      text: historyDepth.toNumber(),
      unit: "eras",
      value: historyDepth.toNumber(),
    });

    return eraSelection;
  }
  return [{ text: 0, unit: "", value: 0 }];
}

type Result = Record<string, string[]>;
/**
 * Query nominations of staking module.
 */
async function queryNominations(api: ApiPromise) {
  const nominators: [StorageKey, Option<Nominations>][] = await api.query.staking.nominators.entries();
  return nominators.reduce((mapped: Result, [key, optNoms]) => {
    if (optNoms.isSome && key.args.length) {
      const nominatorId = key.args[0].toString();
      const { targets } = optNoms.unwrap();

      targets.forEach((_validatorId, index): void => {
        const validatorId = _validatorId.toString();
        // const info = { index: index + 1, nominatorId, submittedIn };

        if (!mapped[validatorId]) {
          mapped[validatorId] = [nominatorId];
        } else {
          mapped[validatorId].push(nominatorId);
        }
      });
    }

    return mapped;
  }, {});
}


function _isWaitingDerive (derive: DeriveStakingElected | DeriveStakingWaiting): derive is DeriveStakingWaiting {
  return !(derive as DeriveStakingElected).nextElected;
}
interface LastEra {
  activeEra: BN;
  eraLength: BN;
  lastEra: BN;
  sessionLength: BN;
}
function _extractSingleTarget (api: ApiPromise, derive: DeriveStakingElected | DeriveStakingWaiting, { activeEra, eraLength, lastEra, sessionLength }: LastEra, historyDepth?: BN): [any[], string[]] {
  const nominators: Record<string, boolean> = {};
  const emptyExposure = api.createType('Exposure');
  const earliestEra = historyDepth && lastEra.sub(historyDepth).addn(1);
  const list = derive.info.map(({ accountId, exposure = emptyExposure, stakingLedger, validatorPrefs }): any => {
    // some overrides (e.g. Darwinia Crab) does not have the own/total field in Exposure
    let [bondOwn, bondTotal] = exposure.total
      ? [exposure.own.unwrap(), exposure.total.unwrap()]
      : [BN_ZERO, BN_ZERO];
    const skipRewards = bondTotal.isZero();

    if (bondTotal.isZero()) {
      bondTotal = bondOwn = stakingLedger.total.unwrap();
    }

    const key = accountId.toString();
    const lastEraPayout = !lastEra.isZero()
      ? stakingLedger.claimedRewards[stakingLedger.claimedRewards.length - 1]
      : undefined;

    // only use if it is more recent than historyDepth
    let lastPayout: BN | undefined = earliestEra && lastEraPayout && lastEraPayout.gt(earliestEra)
      ? lastEraPayout
      : undefined;

    if (lastPayout && !sessionLength.eq(BN_ONE)) {
      lastPayout = lastEra.sub(lastPayout).mul(eraLength);
    }

    return {
      accountId,
      bondOther: bondTotal.sub(bondOwn),
      bondOwn,
      bondShare: 0,
      bondTotal,
      commissionPer: validatorPrefs.commission.unwrap().toNumber() / 10_000_000,
      exposure,
      isActive: !skipRewards,
      isElected: !_isWaitingDerive(derive) && derive.nextElected.some((e) => e.eq(accountId)),
      key,
      knownLength: activeEra.sub(stakingLedger.claimedRewards[0] || activeEra),
      lastPayout,
      numNominators: (exposure.others || []).length,
      numRecentPayouts: earliestEra
        ? stakingLedger.claimedRewards.filter((era) => era.gte(earliestEra)).length
        : 0,
      rankBondOther: 0,
      rankBondOwn: 0,
      rankBondTotal: 0,
      rankNumNominators: 0,
      rankOverall: 0,
      rankReward: 0,
      skipRewards,
      stakedReturn: 0,
      stakedReturnCmp: 0,
      validatorPrefs
    };
  });

  return [list, Object.keys(nominators)];
}
function _calcInflation (api: ApiPromise, totalStaked: BN, totalIssuance: BN): Inflation {
  const { falloff, idealStake, maxInflation, minInflation } = getInflationParams(api);
  const stakedFraction = totalStaked.muln(1_000_000).div(totalIssuance).toNumber() / 1_000_000;
  const idealInterest = maxInflation / idealStake;
  const inflation = 100 * (minInflation + (
    stakedFraction <= idealStake
      ? (stakedFraction * (idealInterest - (minInflation / idealStake)))
      : (((idealInterest * idealStake) - minInflation) * Math.pow(2, (idealStake - stakedFraction) / falloff))
  ));

  return {
    inflation,
    stakedReturn: inflation / stakedFraction
  };
}
function mapIndex (mapBy: any): (info: any, index: number) => any {
  return (info, index): any => {
    info[mapBy] = index + 1;

    return info;
  };
}
function sortValidators (list: any[]): any[] {
  const existing: string[] = [];

  return list
    .filter((a): boolean => {
      const s = a.accountId.toString();

      if (!existing.includes(s)) {
        existing.push(s);

        return true;
      }

      return false;
    })
    // .filter((a) => a.bondTotal.gtn(0))
    // ignored, not used atm
    // .sort((a, b) => b.commissionPer - a.commissionPer)
    // .map(mapIndex('rankComm'))
    // .sort((a, b) => b.bondOther.cmp(a.bondOther))
    // .map(mapIndex('rankBondOther'))
    // .sort((a, b) => b.bondOwn.cmp(a.bondOwn))
    // .map(mapIndex('rankBondOwn'))
    .sort((a, b) => b.bondTotal.cmp(a.bondTotal))
    .map(mapIndex('rankBondTotal'))
    // .sort((a, b) => b.validatorPayment.cmp(a.validatorPayment))
    // .map(mapIndex('rankPayment'))
    .sort((a, b) => a.stakedReturnCmp - b.stakedReturnCmp)
    .map(mapIndex('rankReward'))
    // ignored, not used atm
    // .sort((a, b) => b.numNominators - a.numNominators)
    // .map(mapIndex('rankNumNominators'))
    .sort((a, b) =>
      (b.stakedReturnCmp - a.stakedReturnCmp) ||
      (a.commissionPer - b.commissionPer) ||
      (b.rankBondTotal - a.rankBondTotal)
    )
    .map(mapIndex('rankOverall'))
    .sort((a, b) =>
      a.isFavorite === b.isFavorite
        ? 0
        : (a.isFavorite ? -1 : 1)
    );
}
interface SortedTargets {
  avgStaked?: BN;
  electedIds?: string[];
  inflation: Inflation;
  lowStaked?: BN;
  medianComm: number;
  nominators?: string[];
  totalStaked?: BN;
  totalIssuance?: BN;
  validators?: any[];
  validatorIds?: string[];
  waitingIds?: string[];
}
function _extractTargetsInfo(api: ApiPromise, electedDerive: DeriveStakingElected, waitingDerive: DeriveStakingWaiting, totalIssuance: BN, lastEraInfo: LastEra, historyDepth?: BN): Partial<SortedTargets> {
  const [elected, nominators] = _extractSingleTarget(api, electedDerive, lastEraInfo, historyDepth);
  const [waiting] = _extractSingleTarget(api, waitingDerive, lastEraInfo);
  const activeTotals = elected
    .filter(({ isActive }) => isActive)
    .map(({ bondTotal }) => bondTotal)
    .sort((a, b) => a.cmp(b));
  const totalStaked = activeTotals.reduce((total: BN, value) => total.iadd(value), new BN(0));
  const avgStaked = totalStaked.divn(activeTotals.length);
  const inflation = _calcInflation(api, totalStaked, totalIssuance);

  // add the explicit stakedReturn
  !avgStaked.isZero() && elected.forEach((e): void => {
    if (!e.skipRewards) {
      e.stakedReturn = inflation.stakedReturn * avgStaked.muln(1_000_000).div(e.bondTotal).toNumber() / 1_000_000;
      e.stakedReturnCmp = e.stakedReturn * (100 - e.commissionPer) / 100;
    }
  });

  // all validators, calc median commission
  const validators = sortValidators(arrayFlatten([elected, waiting]));
  const commValues = validators.map(({ commissionPer }) => commissionPer).sort((a, b) => a - b);
  const midIndex = Math.floor(commValues.length / 2);
  const medianComm = commValues.length
    ? commValues.length % 2
      ? commValues[midIndex]
      : (commValues[midIndex - 1] + commValues[midIndex]) / 2
    : 0;

  // ids
  const electedIds = elected.map(({ key }) => key);
  const waitingIds = waiting.map(({ key }) => key);
  const validatorIds = arrayFlatten([electedIds, waitingIds]);

  return {
    avgStaked,
    inflation,
    lowStaked: activeTotals[0] || BN_ZERO,
    medianComm,
    nominators,
    totalIssuance,
    totalStaked,
    validatorIds,
    validators,
    waitingIds
  };
}
const _transfromEra = ({ activeEra, eraLength, sessionLength }: DeriveSessionInfo): LastEra => ({
  activeEra,
  eraLength,
  lastEra: activeEra.isZero() ? BN_ZERO : activeEra.subn(1),
  sessionLength
});
/**
 * Query all validators info.
 */
async function querySortedTargets(api: ApiPromise) {
 const data = await Promise.all([
  api.query.staking.historyDepth(),
  api.query.balances.totalIssuance(),
  api.derive.staking.electedInfo({withExposure: true, withPrefs: true}),
  api.derive.staking.waitingInfo({withPrefs: true}),
  api.derive.session.info(),
 ]);
 
 const partial = data[1] && data[2] && data[3] && data[4]
 ? _extractTargetsInfo(api, data[2], data[3], data[1], _transfromEra(data[4]), data[0])
 : {};
 return { inflation: { inflation: 0, stakedReturn: 0 }, medianComm: 0, ...partial };
}

async function _getOwnStash(api: ApiPromise, accountId: string): Promise<[string, boolean]> {
  let stashId = accountId;
  let isOwnStash = false;
  const ownStash = await Promise.all([
    api.query.staking.bonded(accountId),
    api.query.staking.ledger(accountId),
  ]);
  if (ownStash[0].isSome) {
    isOwnStash = true;
  }
  if (ownStash[1].isSome) {
    stashId = ownStash[1].unwrap().stash.toString();
    if (accountId != stashId) {
      isOwnStash = false;
    }
  }
  return [stashId, isOwnStash];
}

function _toIdString(id: any) {
  return id ? id.toString() : null;
}

function _extractStakerState(
  accountId,
  stashId,
  allStashes,
  [
    isOwnStash,
    {
      controllerId: _controllerId,
      exposure,
      nextSessionIds,
      nominators,
      rewardDestination,
      sessionIds,
      stakingLedger,
      validatorPrefs,
    },
    validateInfo,
  ]
) {
  const isStashNominating = !!nominators?.length;
  const isStashValidating =
    !(Array.isArray(validateInfo)
      ? validateInfo[1].isEmpty
      : validateInfo.isEmpty) || !!allStashes?.includes(stashId);
  const nextConcat = u8aConcat(...nextSessionIds.map((id: any) => id.toU8a()));
  const currConcat = u8aConcat(...sessionIds.map((id: any) => id.toU8a()));
  const controllerId = _toIdString(_controllerId);

  return {
    controllerId,
    destination: rewardDestination?.toString().toLowerCase(),
    destinationId: rewardDestination?.toNumber() || 0,
    exposure,
    hexSessionIdNext: u8aToHex(nextConcat, 48),
    hexSessionIdQueue: u8aToHex(
      currConcat.length ? currConcat : nextConcat,
      48
    ),
    isOwnController: accountId == controllerId,
    isOwnStash,
    isStashNominating,
    isStashValidating,
    // we assume that all ids are non-null
    nominating: nominators?.map(_toIdString),
    sessionIds: (nextSessionIds.length ? nextSessionIds : sessionIds).map(
      _toIdString
    ),
    stakingLedger,
    stashId,
    validatorPrefs,
  };
}

function _extractInactiveState(
  api: ApiPromise,
  stashId: string,
  slashes: any,
  nominees: any,
  activeEra: any,
  submittedIn: any,
  exposures:any
) {
  const max = api.consts.staking?.maxNominatorRewardedPerValidator;

  // chilled
  const nomsChilled = nominees.filter((_: any, index: number) => {
    if (slashes[index].isNone) {
      return false;
    }

    const { lastNonzeroSlash } = slashes[index].unwrap();

    return !lastNonzeroSlash.isZero() && lastNonzeroSlash.gte(submittedIn);
  });

  // all nominations that are oversubscribed
  const nomsOver = exposures
    .map(({ others }) =>
      others.sort((a: any, b:any) => b.value.unwrap().cmp(a.value.unwrap()))
    )
    .map((others: any, index:any) =>
      !max || max.gtn(others.map(({ who }) => who.toString()).indexOf(stashId))
        ? null
        : nominees[index]
    )
    .filter((nominee: any) => !!nominee && !nomsChilled.includes(nominee));

  // first a blanket find of nominations not in the active set
  let nomsInactive = exposures
    .map((exposure:any, index:any) =>
      exposure.others.some(({ who }) => who.eq(stashId))
        ? null
        : nominees[index]
    )
    .filter((nominee:any) => !!nominee);

  // waiting if validator is inactive or we have not submitted long enough ago
  const nomsWaiting = exposures
    .map((exposure:any, index: number) =>
      exposure.total.unwrap().isZero() ||
      (nomsInactive.includes(nominees[index]) && submittedIn.eq(activeEra))
        ? nominees[index]
        : null
    )
    .filter((nominee:any) => !!nominee)
    .filter(
      (nominee:any) => !nomsChilled.includes(nominee) && !nomsOver.includes(nominee)
    );

  // filter based on all inactives
  const nomsActive = nominees.filter(
    (nominee:any) =>
      !nomsInactive.includes(nominee) &&
      !nomsChilled.includes(nominee) &&
      !nomsOver.includes(nominee)
  );

  // inactive also contains waiting, remove those
  nomsInactive = nomsInactive.filter(
    (nominee:any) =>
      !nomsWaiting.includes(nominee) &&
      !nomsChilled.includes(nominee) &&
      !nomsOver.includes(nominee)
  );

  return {
    nomsActive,
    nomsChilled,
    nomsInactive,
    nomsOver,
    nomsWaiting,
  };
}
async function _getInactives(api: ApiPromise, stashId: string, nominees: any) {
  const indexes = await api.derive.session.indexes();
  const [optNominators, ...exposuresAndSpans] = await Promise.all(
    [api.query.staking.nominators(stashId)]
      .concat(
        nominees.map((id: string) =>
          api.query.staking.erasStakers(indexes.activeEra, id)
        )
      )
      .concat(nominees.map((id: string) => api.query.staking.slashingSpans(id)))
  );
  const exposures = exposuresAndSpans.slice(0, nominees.length);
  const slashes = exposuresAndSpans.slice(nominees.length);
  return _extractInactiveState(
    api,
    stashId,
    slashes,
    nominees,
    indexes.activeEra,
    optNominators.unwrapOrDefault().submittedIn,
    exposures
  );
}
function _extractUnbondings(stakingInfo: any, progress: any) {
  if (!stakingInfo?.unlocking || !progress) {
    return { mapped: [], total: BN_ZERO };
  }

  const mapped = stakingInfo.unlocking
    .filter(
      ({ remainingEras, value }) =>
        value.gt(BN_ZERO) && remainingEras.gt(BN_ZERO)
    )
    .map((unlock: any) => [
      unlock,
      unlock.remainingEras
        .sub(BN_ONE)
        .imul(progress.eraLength)
        .iadd(progress.eraLength)
        .isub(progress.eraProgress)
        .toNumber(),
    ]);
  const total = mapped.reduce(
    (total: BN, [{ value }]) => total.iadd(value),
    new BN(0)
  );

  return {
    mapped: mapped.map((i: any) => [
      formatBalance(i[0].value, { forceUnit: "-", withSi: false }),
      i[1],
    ]),
    total,
  };
}

async function getOwnStashInfo(api: ApiPromise, accountId: string) {
  const [stashId, isOwnStash] = await _getOwnStash(api, accountId);
  const [account, validators, allStashes, progress] = await Promise.all([
    api.derive.staking.account(stashId),
    api.query.staking.validators(stashId),
    api.derive.staking.stashes().then((res) => res.map((i) => i.toString())),
    api.derive.session.progress(),
  ]);
  const stashInfo = _extractStakerState(accountId, stashId, allStashes, [
    isOwnStash,
    account,
    validators,
  ]);
  const unbondings = _extractUnbondings(account, progress);
  let inactives: any;
  if (stashInfo.nominating && stashInfo.nominating.length) {
    inactives = await _getInactives(api, stashId, stashInfo.nominating);
  }
  return {
    account,
    ...stashInfo,
    inactives,
    unbondings,
  };
}

/**
 * Query slashing span as a param to redeem rewards.
 */
async function getSlashingSpans(api: ApiPromise, stashId: string) {
  const res = await api.query.staking.slashingSpans(stashId);
  return res.isNone ? 0 : res.unwrap().prior.length + 1;
}

export default {
  loadValidatorRewardsData,
  getAccountRewardsEraOptions,
  loadAccountRewardsData,
  querySortedTargets,
  queryNominations,
  getOwnStashInfo,
  getSlashingSpans,
};

import { ApiPromise } from "@polkadot/api";
import {
  DeriveStakerReward,
  DeriveStakingElected,
  DeriveStakingWaiting
} from "@polkadot/api-derive/types";
import type { Option, StorageKey, u32, Vec  } from '@polkadot/types';
import { u8aConcat, u8aToHex, BN, BN_ZERO, BN_MILLION, BN_ONE,BN_HUNDRED,BN_MAX_INTEGER, formatBalance, isFunction, arrayFlatten } from '@polkadot/util';
import {  Nominations } from "@polkadot/types/interfaces";

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

    labels.push(era.toString());
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
    labels.push(era.toString());

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
    labels.push(era.toString());
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

function _groupByValidator(allRewards: Record<string, DeriveStakerReward[]>) {
  return Object.entries(allRewards)
    .reduce((grouped, [stashId, rewards]) => {
      rewards
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
function _getAvailable(allRewards: Record<string, DeriveStakerReward[]>) {
  if (allRewards) {
    const stashes = _extractStashes(allRewards);
    const stashTotal = stashes.length
      ? stashes.reduce((total, { available }) => total.add(available), BN_ZERO)
      : null;

    return {
      stashTotal,
      stashes,
      validators: _groupByValidator(allRewards),
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
  const res = _getAvailable(allRewards);

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
/**
 * Query nominations count of staking module.
 */
async function queryNominationsCount(api: ApiPromise) {
  const nominations = await queryNominations(api);
  const res = {};
  Object.keys(nominations).forEach(k => {
    res[k] = nominations[k].length;
  });
  return res;
}


interface LastEra {
  activeEra: BN;
  eraLength: BN;
  lastEra: BN;
  sessionLength: BN;
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
  counterForNominators?: BN;
  counterForValidators?: BN;
  electedIds?: string[];
  historyDepth?: BN;
  inflation: Inflation;
  lastEra?: BN;
  lowStaked?: BN;
  medianComm: number;
  maxNominatorsCount?: BN;
  maxValidatorsCount?: BN;
  minNominated: BN;
  minNominatorBond?: BN;
  minValidatorBond?: BN;
  nominators?: string[];
  nominateIds?: string[];
  totalStaked?: BN;
  totalIssuance?: BN;
  validators?: any[];
  validatorIds?: string[];
  waitingIds?: string[];
}

function _extractBaseInfo (api: ApiPromise, electedDerive: DeriveStakingElected, waitingDerive: DeriveStakingWaiting, totalIssuance: BN, lastEraInfo: LastEra, historyDepth?: BN): Partial<SortedTargets> {
  const [elected, nominators] = _extractSingle(api,  electedDerive,  lastEraInfo, historyDepth, true);
  const [waiting] = _extractSingle(api, waitingDerive, lastEraInfo);
  const activeTotals = elected
    .filter(({ isActive }) => isActive)
    .map(({ bondTotal }) => bondTotal)
    .sort((a, b) => a.cmp(b));
  const totalStaked = activeTotals.reduce((total: BN, value) => total.iadd(value), new BN(0));
  const avgStaked = totalStaked.divn(activeTotals.length);

  // all validators, calc median commission
  const minNominated = Object.values(nominators).reduce((min: BN, value) => {
    return min.isZero() || value.lt(min)
      ? value
      : min;
  }, BN_ZERO);
  const validators = arrayFlatten([elected, waiting]);
  const commValues = validators.map(({ commissionPer }) => commissionPer).sort((a, b) => a - b);
  const midIndex = Math.floor(commValues.length / 2);
  const medianComm = commValues.length
    ? commValues.length % 2
      ? commValues[midIndex]
      : (commValues[midIndex - 1] + commValues[midIndex]) / 2
    : 0;

  // ids
  const waitingIds = waiting.map(({ key }) => key);
  const validatorIds = arrayFlatten([
    elected.map(({ key }) => key),
    waitingIds
  ]);
  const nominateIds = arrayFlatten([
    elected.filter(({ isBlocking }) => !isBlocking).map(({ key }) => key),
    waiting.filter(({ isBlocking }) => !isBlocking).map(({ key }) => key)
  ]);

  return {
    avgStaked,
    lastEra: lastEraInfo.lastEra,
    lowStaked: activeTotals[0] || BN_ZERO,
    medianComm,
    minNominated,
    nominateIds,
    nominators: Object.keys(nominators),
    totalIssuance,
    totalStaked,
    validatorIds,
    validators,
    waitingIds
  };
}

function _extractSingle (api: ApiPromise, derive: DeriveStakingElected | DeriveStakingWaiting, { activeEra, eraLength, lastEra, sessionLength }: LastEra, historyDepth?: BN, withReturns?: boolean): [ValidatorInfo[], Record<string, BN>] {
  const nominators: Record<string, BN> = {};
  const emptyExposure = api.createType('SpStakingExposurePage');
  const emptyExposureMeta = api.createType('SpStakingPagedExposureMetadata');
  const earliestEra = historyDepth && lastEra.sub(historyDepth).iadd(BN_ONE);
  const list = new Array<any>(derive.info.length);

  for (let i = 0; i < derive.info.length; i++) {
    const { accountId, claimedRewardsEras, exposureMeta, exposurePaged, stakingLedger, validatorPrefs } = derive.info[i];
    const exp = exposurePaged.isSome && exposurePaged.unwrap();
    const expMeta = exposureMeta.isSome && exposureMeta.unwrap();
    // some overrides (e.g. Darwinia Crab) does not have the own/total field in Exposure
    let [bondOwn, bondTotal] = exp && expMeta
      ? [expMeta.own.unwrap(), expMeta.total.unwrap()]
      : [BN_ZERO, BN_ZERO];

    const skipRewards = bondTotal.isZero();

    if (skipRewards) {
      bondTotal = bondOwn = stakingLedger.total?.unwrap() || BN_ZERO;
    }

    // some overrides (e.g. Darwinia Crab) does not have the value field in IndividualExposure
    const minNominated = ((exp && exp.others) || []).reduce((min: BN, { value = api.createType('Compact<Balance>') }): BN => {
      const actual = value.unwrap();

      return min.isZero() || actual.lt(min)
        ? actual
        : min;
    }, BN_ZERO);

    const key = accountId.toString();
    const rewards = _getLegacyRewards(stakingLedger, claimedRewardsEras);

    const lastEraPayout = !lastEra.isZero()
      ? rewards[rewards.length - 1]
      : undefined;

    list[i] = {
      accountId,
      bondOther: bondTotal.sub(bondOwn),
      bondOwn,
      bondShare: 0,
      bondTotal,
      commissionPer: validatorPrefs.commission.unwrap().toNumber() / 10_000_000,
      exposure: {...(expMeta || emptyExposureMeta).toJSON(), ...(exp || emptyExposure).toJSON()},
      isActive: !skipRewards,
      isBlocking: !!(validatorPrefs.blocked && validatorPrefs.blocked.isTrue),
      isElected:  (derive as DeriveStakingElected).nextElected && derive.nextElected.some((e) => e.eq(accountId)),
      key,
      knownLength: activeEra.sub(rewards[0] || activeEra),
      // only use if it is more recent than historyDepth
      lastPayout: earliestEra && lastEraPayout && lastEraPayout.gt(earliestEra) && !sessionLength.eq(BN_ONE)
        ? lastEra.sub(lastEraPayout).mul(eraLength)
        : undefined,
      minNominated,
      numNominators: ((exp && exp.others) || []).length,
      numRecentPayouts: earliestEra
        ? rewards.filter((era) => era.gte(earliestEra)).length
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
      validatorPrefs,
      withReturns
    };
  }

  return [list, nominators];
}

function _getLegacyRewards (ledger: any, claimedRewardsEras: Vec<u32>): u32[] {
  const legacyRewards = ledger.legacyClaimedRewards || (ledger as any).claimedRewards || [];

  return legacyRewards.concat(claimedRewardsEras.toArray());
}

const EMPTY: Inflation = { idealInterest: 0, idealStake: 0, inflation: 0, stakedFraction: 0, stakedReturn: 0 };

function _calcInflation (api: ApiPromise, totalStaked: BN, totalIssuance: BN, numAuctions: BN): Inflation {
  const { auctionAdjust, auctionMax, falloff, maxInflation, minInflation, stakeTarget } = getInflationParams(api);
  const stakedFraction = totalStaked.isZero() || totalIssuance.isZero()
    ? 0
    : totalStaked.mul(BN_MILLION).div(totalIssuance).toNumber() / BN_MILLION.toNumber();
  // Ideal is less based on the actual auctions, see
  // https://github.com/paritytech/polkadot/blob/816cb64ea16102c6c79f6be2a917d832d98df757/runtime/kusama/src/lib.rs#L531
  const idealStake = stakeTarget - (Math.min(auctionMax, numAuctions.toNumber()) * auctionAdjust);
  const idealInterest = maxInflation / idealStake;
  // inflation calculations, see
  // https://github.com/paritytech/substrate/blob/0ba251c9388452c879bfcca425ada66f1f9bc802/frame/staking/reward-fn/src/lib.rs#L28-L54
  const inflation = 100 * (minInflation + (
    stakedFraction <= idealStake
      ? (stakedFraction * (idealInterest - (minInflation / idealStake)))
      : (((idealInterest * idealStake) - minInflation) * Math.pow(2, (idealStake - stakedFraction) / falloff))
  ));

  return {
    idealInterest,
    idealStake,
    inflation,
    stakedFraction,
    stakedReturn: stakedFraction
      ? (inflation / stakedFraction)
      : 0
  };
}

async function _useInflation (api: ApiPromise, totalStaked?: BN) {
  const [totalIssuance, auctionCounter] = await Promise.all([api.query.balances?.totalIssuance(), api.query.auctions?.auctionCounter()] );

  const numAuctions = api.query.auctions
  ? auctionCounter
  : BN_ZERO;
  
  if (numAuctions && totalIssuance && totalStaked ) {
    return _calcInflation(api, totalStaked, totalIssuance, numAuctions);
  }

  return  { idealInterest: 0, idealStake: 0, inflation: 0, stakedFraction: 0, stakedReturn: 0 };
}

function _addReturns (inflation: Inflation, baseInfo: Partial<SortedTargets>): Partial<SortedTargets> {
  const avgStaked = baseInfo.avgStaked;
  const validators = baseInfo.validators;

  if (!validators) {
    return baseInfo;
  }

  avgStaked && !avgStaked.isZero() && validators.forEach((v): void => {
    if (!v.skipRewards && v.withReturns) {
      const adjusted = avgStaked.mul(BN_HUNDRED).imuln(inflation.stakedReturn).div(v.bondTotal);

      // in some cases, we may have overflows... protect against those
      v.stakedReturn = (adjusted.gt(BN_MAX_INTEGER) ? BN_MAX_INTEGER : adjusted).toNumber() / BN_HUNDRED.toNumber();
      v.stakedReturnCmp = v.stakedReturn * (100 - v.commissionPer) / 100;
    }
  });

  return { ...baseInfo, validators: sortValidators(validators) };
}
/**
 * Query all validators info.
 */
async function querySortedTargets(api: ApiPromise) {
  const historyDepth = api.consts.staking.historyDepth;
  const [ counterForNominators, counterForValidators, maxNominatorsCount, maxValidatorsCount, minNominatorBond, minValidatorBond, totalIssuance ]  = await Promise.all([
    api.query.staking.counterForNominators(),
    api.query.staking.counterForValidators(),
    api.query.staking.maxNominatorsCount(),
    api.query.staking.maxValidatorsCount(),
    api.query.staking.minNominatorBond(),
    api.query.staking.minValidatorBond(),
    api.query.balances?.totalIssuance()
  ]);
  const [ electedInfo, waitingInfo, { activeEra, eraLength, sessionLength } ]  = await Promise.all([
    api.derive.staking.electedInfo({ withClaimedRewardsEras: false, withController: true, withExposure: true, withExposureMeta: true, withPrefs: true }),
    api.derive.staking.waitingInfo({ withController: true, withPrefs: true }),
    api.derive.session.info()
  ]);
 
  const lastEraInfo =  {
    activeEra,
    eraLength,
    lastEra: activeEra.isZero()
      ? BN_ZERO
      : activeEra.sub(BN_ONE),
    sessionLength
  }

 const baseInfo = (electedInfo && lastEraInfo && totalIssuance && waitingInfo)
    ? _extractBaseInfo(api, electedInfo, waitingInfo, totalIssuance, lastEraInfo,( api.consts.staking.historyDepth || historyDepth) as any)
    : {}
 const inflation = await  _useInflation(api, baseInfo?.totalStaked);

 return {
  counterForNominators,
  counterForValidators,
  historyDepth: api.consts.staking.historyDepth || historyDepth,
  inflation,
  maxNominatorsCount: maxNominatorsCount && (maxNominatorsCount as any).isSome
    ? (maxNominatorsCount as any).unwrap()
    : undefined,
  maxValidatorsCount: maxValidatorsCount && (maxValidatorsCount as any).isSome
    ? (maxValidatorsCount as any).unwrap()
    : undefined,
  medianComm: 0,
  minNominated: BN_ZERO,
  minNominatorBond,
  minValidatorBond,
  ...(
    inflation?.stakedReturn
      ? _addReturns(inflation, baseInfo)
      : baseInfo
  )
 };
}

async function _getOwnStash(api: ApiPromise, accountId: string): Promise<[string, boolean]> {
  let stashId = accountId;
  let isOwnStash = false;
  const ownStash = await Promise.all([
    api.query.staking.bonded(accountId),
    api.query.staking.ledger(accountId),
  ]);
  if ((ownStash[0] as any).isSome) {
    isOwnStash = true;
  }
  if ((ownStash[1] as any).isSome) {
    stashId = (ownStash[1] as any).unwrap().stash.toString();
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
  queryNominationsCount,
  getOwnStashInfo,
  getSlashingSpans,
};

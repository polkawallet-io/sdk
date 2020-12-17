import { ApiPromise } from "@polkadot/api";
import {
  DeriveStakingOverview,
  DeriveStakerReward,
} from "@polkadot/api-derive/types";
import { u8aConcat, u8aToHex, BN_ZERO, BN_ONE, formatBalance, isFunction } from '@polkadot/util';
import { AccountId } from "@polkadot/types/interfaces";
import BN from "bn.js";

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

function _accountsToString(accounts: AccountId[]) {
  return accounts.map((accountId) => accountId.toString());
}

function _filterAccounts(accounts = [], without: any[]) {
  return accounts.filter((accountId) => !without.includes(accountId));
}

function _getNominators(nominations: any[]) {
  return nominations.reduce((mapped, [key, optNoms]) => {
    if (optNoms.isSome) {
      const nominatorId = key.args[0].toString();

      optNoms.unwrap().targets.forEach((_validatorId: any, index: number) => {
        const validatorId = _validatorId.toString();
        const info = [nominatorId, index + 1];

        if (!mapped[validatorId]) {
          mapped[validatorId] = [info];
        } else {
          mapped[validatorId].push(info);
        }
      });
    }

    return mapped;
  }, {});
}

/**
 * Query overview of staking module.
 */
async function fetchStakingOverview(api: ApiPromise) {
  const data = await Promise.all([
    api.derive.staking.overview(),
    api.derive.staking.stashes(),
    api.query.staking.nominators.entries(),
  ]);
  const stakingOverview: DeriveStakingOverview = data[0];
  const allStashes = _accountsToString(data[1]);
  const next = allStashes.filter(
    (e) => !stakingOverview.validators.includes(e as any)
  );
  const nominators = _getNominators(data[2]);

  const allElected = _accountsToString(stakingOverview.nextElected);
  const validatorIds = _accountsToString(stakingOverview.validators);
  const validators = _filterAccounts(validatorIds, []);
  const elected = _filterAccounts(allElected, validatorIds);
  const waiting = _filterAccounts(next, allElected);

  return {
    elected,
    validators,
    waiting,
    nominators,
  };
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
  fetchStakingOverview,
  getOwnStashInfo,
  getSlashingSpans,
};

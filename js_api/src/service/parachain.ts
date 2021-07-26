import { ApiPromise } from '@polkadot/api';
import type { TrieIndex, BlockNumber } from '@polkadot/types/interfaces';
import {  u8aConcat, u8aToHex, BN_ZERO, BN_ONE, u8aEq, stringToU8a } from '@polkadot/util';

import { blake2AsU8a } from '@polkadot/util-crypto';
import type { u32 } from '@polkadot/types';
import BN from 'bn.js';

const CROWD_PREFIX = stringToU8a('modlpy/cfund');
const RANGES_DEFAULT: [number, number][] = [
  [0, 0], [0, 1], [0, 2], [0, 3],
  [1, 1], [1, 2], [1, 3],
  [2, 2], [2, 3],
  [3, 3]
];

function _isU32 (leasePeriodsPerSlot: unknown): leasePeriodsPerSlot is u32 {
  return !!leasePeriodsPerSlot;
}

function _getLeaseRanges (api: ApiPromise): [number, number][] {
  if (_isU32(api.consts.auctions?.leasePeriodsPerSlot)) {
    const ranges: [number, number][] = [];
    for (let i = 0; api.consts.auctions.leasePeriodsPerSlot.gtn(i); i++) {
      for (let j = i; api.consts.auctions.leasePeriodsPerSlot.gtn(j); j++) {
        ranges.push([i, j]);
      }
    }
    return ranges;
  }
  return RANGES_DEFAULT;
}

function _isNewWinners (a: any[], b: any[]): boolean {
  return JSON.stringify({ w: a }) !== JSON.stringify({ w: b });
}

function _extractWinners (ranges: [number, number][], auctionInfo: any, optData: any): any[] {
  return optData.isNone
    ? []
    : optData.unwrap().reduce((winners, optEntry, index): any[] => {
      if (optEntry.isSome) {
        const [accountId, paraId, value] = optEntry.unwrap();
        const period = auctionInfo.leasePeriod || BN_ZERO;
        const [first, last] = ranges[index];

        winners.push({
          accountId: accountId.toString(),
          firstSlot: period.addn(first).toNumber(),
          isCrowdloan: u8aEq(CROWD_PREFIX, accountId.subarray(0, CROWD_PREFIX.length)),
          lastSlot: period.addn(last).toNumber(),
          paraId: paraId.toString(),
          value
        });
      }

      return winners;
    }, []);
}

function _createWinning ({ endBlock }: any, blockOffset: BN | null | undefined, winners: any[]): any {
  return {
    blockNumber: endBlock && blockOffset
      ? blockOffset.add(endBlock)
      : blockOffset || BN_ZERO,
    blockOffset: blockOffset || BN_ZERO,
    total: winners.reduce((total, { value }) => total.iadd(value), new BN(0)),
    winners
  };
}

function _extractData (ranges: [number, number][], auctionInfo: any, values: any[]): any[] {
  return values
    .sort(([{ args: [a] }], [{ args: [b] }]) => a.cmp(b))
    .reduce((all: any[], [{ args: [blockOffset] }, optData]): any[] => {
      const winners = _extractWinners(ranges, auctionInfo, optData);

      winners.length && (
        all.length === 0 ||
        _isNewWinners(winners, all[all.length - 1].winners)
      ) && all.push(_createWinning(auctionInfo, blockOffset, winners));

      return all;
    }, [])
    .reverse();
}

function _updateFund (bestNumber: BN, minContribution: BN, data: any, leased: string[]): any {
  if (!data.info) return null;

  return {
    paraId: data.paraId,
    cap: data.info.cap,
    end: data.info.end,
    isCapped: data.info.cap.sub(data.info.raised).lt(minContribution),
    isEnded : bestNumber.gt(data.info.end),
    isWinner : leased.some((l) => l === data.paraId),
    isCrowdloan : true,
    firstSlot : data.info.firstPeriod.toJSON(),
    lastSlot : data.info.lastPeriod.toJSON(),
    value : data.info.raised,
  };
}

function _getCrowdloanBids(auctionInfo: any, funds: any[], rangeMax: BN): any[] | undefined {
  if (auctionInfo && auctionInfo.leasePeriod && funds) {
    const leasePeriodStart = auctionInfo.leasePeriod;
    const leasePeriodEnd = leasePeriodStart.add(rangeMax);

    return funds
      .filter(({ firstSlot, isWinner, lastSlot }) =>
        !isWinner &&
        firstSlot >= leasePeriodStart.toNumber() &&
        lastSlot <= leasePeriodEnd.toNumber()
      )
      .sort((a, b) => b.value.cmp(a.value));
  } else {
    return undefined;
  }
}

function _mergeCrowdLoanBids(winners: any[], loans: any[]): any[] {
  return winners
    .concat(...loans.filter(({ firstSlot, lastSlot, paraId, value }) =>
      !winners.some((w) =>
        w.firstSlot == firstSlot &&
        w.lastSlot == lastSlot
      ) &&
      !loans.some((e) =>
        (paraId !== e.paraId) &&
        firstSlot == e.firstSlot &&
        lastSlot == e.lastSlot &&
        value.lt(e.value)
      )
    ))
    .map((w): any =>
      loans.find(({ firstSlot, lastSlot, value }) =>
        w.firstSlot == firstSlot &&
        w.lastSlot == lastSlot &&
        w.value.lt(value)
      ) || w
    )
    .sort((a, b) => a.firstSlot == b.firstSlot ?  a.lastSlot > b.lastSlot ? 1 : -1 : a.firstSlot > b.firstSlot ? 1 : -1);
}

async function _queryAuctionInfo(api: ApiPromise) {
  const data = await Promise.all([
    api.query.auctions?.auctionCounter(),
    api.query.auctions?.auctionInfo()
  ]);
  const info = (data[1] as any).unwrapOr([null, null]);
  return {
    numAuctions: (data[0] as any).toJSON(),
    leasePeriod: info[0],
    endBlock: info[1],
  };
}

/**
 * query winners info of active auction.
 */
 async function queryAuctionWithWinners(api: ApiPromise) {
  const minContribution = api.consts.crowdloan.minContribution as BlockNumber;
  const ranges = _getLeaseRanges(api);
  const [bestNumber, auctionInfo, fundData, leasesData, initialEntries] = await Promise.all([
    api.derive.chain.bestNumber(),
    _queryAuctionInfo(api),
    api.query.crowdloan.funds.entries(),
    api.query.slots.leases.entries(),
    api.query.auctions?.winning.entries()
  ]);

  const leases = leasesData.map(([paraId]) => paraId.toHuman()[0].replace(/,/g, ""));
  const funds = fundData.map(([paraId, info]) => _updateFund(bestNumber, minContribution, {info: (info as any).unwrapOr(null), paraId: paraId.toHuman()[0].replace(/,/g, "")}, leases)).filter(i => !!i);
  const loans = _getCrowdloanBids(auctionInfo, funds, new BN(ranges[ranges.length - 1][1]));

  const winningData = _extractData(ranges, auctionInfo, initialEntries);
  return {
    auction: !!auctionInfo.leasePeriod ? {
      ...auctionInfo,
      bestNumber: bestNumber.toString(),
      leasePeriod: auctionInfo.leasePeriod.toNumber(),
      leaseEnd: auctionInfo.leasePeriod.add(api.consts.auctions.leasePeriodsPerSlot as u32).isub(BN_ONE).toNumber()
    } : {},
    funds,
    winners: _mergeCrowdLoanBids(winningData[0]?.winners || [], loans || []),
  };
}

/**
 * query crowd loan contributions of an account.
 *
 * @param {String} paraId
 * @param {String} pubKey
 */
async function queryUserContributions(api: ApiPromise, paraId: string, pubKey: string) {
  const fund = await api.query.crowdloan.funds(paraId) as any;
  const childKey = _createChildKey(fund.unwrap().trieIndex);
  const value = await api.rpc.childstate.getStorage(childKey, pubKey);
  if (value.isSome) {
    return api.createType('(Balance, Vec<u8>)' as any, value.unwrap()).toJSON()[0].toString();
  }
  return '0';
}

function _createChildKey (trieIndex: TrieIndex): string {
  return u8aToHex(
    u8aConcat(
      ':child_storage:default:',
      blake2AsU8a(
        u8aConcat('crowdloan', trieIndex.toU8a())
      )
    )
  );
}

export default {
  queryAuctionWithWinners,
  queryUserContributions
};
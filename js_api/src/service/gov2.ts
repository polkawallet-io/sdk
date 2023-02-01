import { ApiPromise } from "@polkadot/api";

import { BN_ZERO, BN_ONE, BN_BILLION, BN, bnMax, bnMin, stringPascalCase, formatNumber } from "@polkadot/util";

function _isConvictionTally(tally: any) {
  return !!tally.support && !tally.bareAyes;
}

function _isConvictionVote(info: any) {
  return info.isOngoing && _isConvictionTally(info.asOngoing.tally);
}

function _getTrackName(trackId: BN, { name }: any): string {
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

function _group(tracks: any[], totalIssuance?: BN, referenda?: any[]) {
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

      const group = grouped.find(({ track }) => ref.track === track);

      if (!group) {
        // we don't have a group as of yet, create one
        grouped.push({
          key: `track:${ref.trackId.toString()}`,
          referenda: [ref],
          track: ref.track,
          trackGraph: ref.trackGraph,
          trackId: ref.trackId,
          trackName: _getTrackName(ref.trackId, ref.track),
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
async function queryReferendums(api: ApiPromise) {
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
  return _group(tracks, totalIssuance, referenda);
}

export default {
  // gov v2
  queryReferendums,
};

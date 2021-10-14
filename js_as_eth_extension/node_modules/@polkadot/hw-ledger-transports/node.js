// Copyright 2017-2021 @polkadot/hw-ledger authors & contributors
// SPDX-License-Identifier: Apache-2.0
import LedgerHid from '@ledgerhq/hw-transport-node-hid-singleton';
export { packageInfo } from "./packageInfo.js";
export const transports = [{
  create: () => LedgerHid.create(),
  type: 'hid'
}];
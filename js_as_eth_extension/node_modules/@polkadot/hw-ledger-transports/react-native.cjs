"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
Object.defineProperty(exports, "packageInfo", {
  enumerable: true,
  get: function () {
    return _packageInfo.packageInfo;
  }
});
exports.transports = void 0;

var _packageInfo = require("./packageInfo.cjs");

// Copyright 2017-2021 @polkadot/hw-ledger authors & contributors
// SPDX-License-Identifier: Apache-2.0
const transports = [];
exports.transports = transports;
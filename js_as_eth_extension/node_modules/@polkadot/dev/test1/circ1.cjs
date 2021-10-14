"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.circ1 = circ1;

var _circ = require("./circ2.cjs");

// Copyright 2017-2021 @polkadot/dev authors & contributors
// SPDX-License-Identifier: Apache-2.0
// we leave this as a warning... just a test
function circ1() {
  (0, _circ.circ2)();
  return 123;
}
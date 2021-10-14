"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.adder = adder;
exports.blah = blah;
Object.defineProperty(exports, "circ1", {
  enumerable: true,
  get: function () {
    return _circ.circ1;
  }
});
Object.defineProperty(exports, "circ2", {
  enumerable: true,
  get: function () {
    return _circ2.circ2;
  }
});
exports.default = void 0;

var _circ = require("./circ1.cjs");

var _circ2 = require("./circ2.cjs");

// Copyright 2017-2021 @polkadot/dev authors & contributors
// SPDX-License-Identifier: Apache-2.0

/**
 * Some first test link
 * @link ../testRoot.ts
 */
var _default = test => test; // eslint config test


exports.default = _default;

function blah() {
  console.log('123');
}

function adder(a, b) {
  return a + b;
}
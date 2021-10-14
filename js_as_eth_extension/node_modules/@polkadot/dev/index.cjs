"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.echo = void 0;
exports.tester = tester;

var _foo = require("./test1/foo.cjs");

var _index = require("./test1/index.cjs");

var _util = require("./util.cjs");

// Copyright 2017-2021 @polkadot/dev authors & contributors
// SPDX-License-Identifier: Apache-2.0
const SOMETHING = {
  a: 1,
  b: 2,
  c: 555
};
const A = 123;
let count = 0;

function doCallback(fn) {
  fn('test');
}
/**
 * This is just a test file to test the doc generation
 */


const echo = (value, start = 0, end) => {
  const {
    a,
    b,
    c
  } = SOMETHING;
  console.log(a, b, c);
  count++;
  doCallback(a => a);
  (0, _index.blah)();
  return `${count}: ${A}: ${value}`.substr(start, end);
};

exports.echo = echo;

function assert(a) {
  if (!a) {
    console.log('Failed');
    process.exit(-1);
  }
}

function tester() {
  console.log('Running sanity test');
  console.log('  (1)', typeof require === 'undefined' ? 'esm' : 'cjs');
  assert((0, _index.adder)(2, 4) === 6);
  assert((0, _util.addThree)(1, 2, 3) === 6);
  assert((0, _foo.foo)() === 'foobar');
}
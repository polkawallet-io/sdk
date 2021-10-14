// Copyright 2017-2021 @polkadot/dev authors & contributors
// SPDX-License-Identifier: Apache-2.0
import { foo } from "./test1/foo.js";
import { adder, blah } from "./test1/index.js";
import { addThree } from "./util.js";
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


export const echo = (value, start = 0, end) => {
  const {
    a,
    b,
    c
  } = SOMETHING;
  console.log(a, b, c);
  count++;
  doCallback(a => a);
  blah();
  return `${count}: ${A}: ${value}`.substr(start, end);
};

function assert(a) {
  if (!a) {
    console.log('Failed');
    process.exit(-1);
  }
}

export function tester() {
  console.log('Running sanity test');
  console.log('  (1)', typeof require === 'undefined' ? 'esm' : 'cjs');
  assert(adder(2, 4) === 6);
  assert(addThree(1, 2, 3) === 6);
  assert(foo() === 'foobar');
}
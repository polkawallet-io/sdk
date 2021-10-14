// Copyright 2017-2021 @polkadot/dev authors & contributors
// SPDX-License-Identifier: Apache-2.0
export { circ1 } from "./circ1.js";
export { circ2 } from "./circ2.js";
/**
 * Some first test link
 * @link ../testRoot.ts
 */

export default (test => test); // eslint config test

export function blah() {
  console.log('123');
}
export function adder(a, b) {
  return a + b;
}
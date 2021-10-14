import _classPrivateFieldLooseBase from "@babel/runtime/helpers/esm/classPrivateFieldLooseBase";
import _classPrivateFieldLooseKey from "@babel/runtime/helpers/esm/classPrivateFieldLooseKey";

var _something = /*#__PURE__*/_classPrivateFieldLooseKey("something");

// Copyright 2017-2021 @polkadot/dev authors & contributors
// SPDX-License-Identifier: Apache-2.0
export class Testing123 {
  constructor(and) {
    Object.defineProperty(this, _something, {
      writable: true,
      value: 123456789
    });
    this.and = void 0;

    this.setSomething = something => {
      _classPrivateFieldLooseBase(this, _something)[_something] = something;
      return _classPrivateFieldLooseBase(this, _something)[_something];
    };

    this.and = and;
    _classPrivateFieldLooseBase(this, _something)[_something] = _classPrivateFieldLooseBase(this, _something)[_something] & and;
  }

  get something() {
    return _classPrivateFieldLooseBase(this, _something)[_something];
  }

  async doAsync() {
    const res = await new Promise(resolve => resolve(true));
    console.log(res);
    return res;
  }

  toString() {
    return `something=${_classPrivateFieldLooseBase(this, _something)[_something]}`;
  }

}
Testing123.staticProperty = 'babelIsCool';

Testing123.staticFunction = () => Testing123.staticProperty;
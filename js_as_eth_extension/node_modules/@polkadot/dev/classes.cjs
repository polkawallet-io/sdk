"use strict";

var _interopRequireDefault = require("@babel/runtime/helpers/interopRequireDefault");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.Testing123 = void 0;

var _classPrivateFieldLooseBase2 = _interopRequireDefault(require("@babel/runtime/helpers/classPrivateFieldLooseBase"));

var _classPrivateFieldLooseKey2 = _interopRequireDefault(require("@babel/runtime/helpers/classPrivateFieldLooseKey"));

var _something = /*#__PURE__*/(0, _classPrivateFieldLooseKey2.default)("something");

// Copyright 2017-2021 @polkadot/dev authors & contributors
// SPDX-License-Identifier: Apache-2.0
class Testing123 {
  constructor(and) {
    Object.defineProperty(this, _something, {
      writable: true,
      value: 123456789
    });
    this.and = void 0;

    this.setSomething = something => {
      (0, _classPrivateFieldLooseBase2.default)(this, _something)[_something] = something;
      return (0, _classPrivateFieldLooseBase2.default)(this, _something)[_something];
    };

    this.and = and;
    (0, _classPrivateFieldLooseBase2.default)(this, _something)[_something] = (0, _classPrivateFieldLooseBase2.default)(this, _something)[_something] & and;
  }

  get something() {
    return (0, _classPrivateFieldLooseBase2.default)(this, _something)[_something];
  }

  async doAsync() {
    const res = await new Promise(resolve => resolve(true));
    console.log(res);
    return res;
  }

  toString() {
    return `something=${(0, _classPrivateFieldLooseBase2.default)(this, _something)[_something]}`;
  }

}

exports.Testing123 = Testing123;
Testing123.staticProperty = 'babelIsCool';

Testing123.staticFunction = () => Testing123.staticProperty;
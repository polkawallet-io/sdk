"use strict";

var _interopRequireDefault = require("@babel/runtime/helpers/interopRequireDefault");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _react = _interopRequireDefault(require("react"));

var _jsxRuntime = require("react/jsx-runtime");

// Copyright 2017-2021 @polkadot/dev authors & contributors
// SPDX-License-Identifier: Apache-2.0
function Child({
  children,
  className,
  label
}) {
  return /*#__PURE__*/(0, _jsxRuntime.jsxs)("div", {
    className: className,
    children: [label || '', children]
  });
}

function Component({
  children,
  className,
  label
}) {
  const bon = '123';

  if (label === bon) {
    console.error('true');
  }

  try {
    console.log('bon');
  } catch (error) {// ignore;
  }

  console.log('1');
  return /*#__PURE__*/(0, _jsxRuntime.jsxs)("div", {
    className: className,
    children: [/*#__PURE__*/(0, _jsxRuntime.jsx)(Child, {
      className: "child",
      label: label,
      children: children
    }), /*#__PURE__*/(0, _jsxRuntime.jsx)(Child, {
      className: "child",
      children: "bob"
    })]
  });
}

var _default = /*#__PURE__*/_react.default.memo(Component);

exports.default = _default;
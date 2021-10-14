// Copyright 2017-2021 @polkadot/dev authors & contributors
// SPDX-License-Identifier: Apache-2.0
import React from 'react';
import { jsxs as _jsxs } from "react/jsx-runtime";
import { jsx as _jsx } from "react/jsx-runtime";

function Child({
  children,
  className,
  label
}) {
  return /*#__PURE__*/_jsxs("div", {
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
  return /*#__PURE__*/_jsxs("div", {
    className: className,
    children: [/*#__PURE__*/_jsx(Child, {
      className: "child",
      label: label,
      children: children
    }), /*#__PURE__*/_jsx(Child, {
      className: "child",
      children: "bob"
    })]
  });
}

export default /*#__PURE__*/React.memo(Component);
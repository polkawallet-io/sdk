# babel-plugin-module-extension-resolver

[![Build Status (Windows)][image-build-windows]][link-build-windows]
[![Build Status (macOS)][image-build-macos]][link-build-macos]
[![Build Status (Linux)][image-build-linux]][link-build-linux]
[![Examples check][image-examples-check]][link-examples-check]
[![Release][image-release]][link-release]
[![Node.js version][image-engine]][link-engine]
[![License][image-license]][link-license]

Babel plugin that resolves and maps module extensions.

Inspired by [babel-plugin-extension-resolver](https://www.npmjs.com/package/babel-plugin-extension-resolver).

## Examples

By default, all extensions except `.json` is converted into `.js`.
This behavior can be customized by [options](#options).

### JavaScript

Directory structure:

```text
src
├ dir
│ ├ index.js
│ └ lib.js
├ main.js
└ settings.json
```

Input (`main.js`):

```javascript
require("./dir/lib");
require("./dir/lib.js");    // file exists
require("./dir");           // directory has "index.js"
require("./settings");      // ".json" extension
require("./no-such-file");  // file NOT exists
require("dir");             // not begins with "."
```

Output:

```javascript
require("./dir/lib.js");
require("./dir/lib.js");
require("./dir/index.js");
require("./settings.json");
require("./no-such-file");
require("dir");
```

### JavaScript (`.mjs` extension)

Directory structure:

```text
src
├ dir
│ ├ index.mjs
│ └ lib.mjs
└ main.mjs
```

`.babelrc`:

```json
{
  "presets": [
    ["@babel/preset-env", {"modules": false}]
  ],
  "plugins": [
    ["module-extension-resolver", {
      "extensionsToKeep": [".mjs", ".json"]
    }]
  ]
}
```

Input (`main.mjs`):

```javascript
import "./dir/lib";
import "./dir";

export * from "./dir";

async function foo() {
    await import("./dir/lib");
}
```

Run:

```bash
babel src --keep-file-extension
```

Output:

```javascript
import "./dir/lib.mjs";
import "./dir/index.mjs";

export * from "./dir/index.mjs";

async function foo() {
    await import("./dir/lib.mjs");
}
```

### TypeScript

Directory structure:

```text
src
├ dir
│ ├ index.ts
│ └ lib.ts
└ main.ts
```

Input (`main.ts`):

```typescript
import "./dir/lib";
import "./dir";
```

Output:

```javascript
import "./dir/lib.js";
import "./dir/index.js";
```

For complete project, see below examples.

|Language|CommonJS|ES Modules|
|---|---|---|
|ECMAScript with `@babel/preset-env`|[babel-cjs](./examples/babel-cjs)|[babel-esm](./examples/babel-esm)|
|TypeScript with `@babel/preset-typescript`|[ts-babel-cjs](./examples/ts-babel-cjs)|[ts-babel-esm](./examples/ts-babel-esm)|
|TypeScript with `tsc` and Babel|[ts-tsc-cjs](./examples/ts-tsc-cjs)|[ts-tsc-esm](./examples/ts-tsc-esm)|

## Install

```bash
npm i -D babel-plugin-module-extension-resolver
```

## `.babelrc`

```json
{
  "plugins": ["module-extension-resolver"]
}
```

With options:

```json
{
  "plugins": [
    ["module-extension-resolver", {
      "srcExtensions": [".js", ".cjs", ".mjs", ".es", ".es6", ".ts", ".node", ".json"],
      "dstExtension": ".js",
      "extensionsToKeep": [".json"]
    }]
  ]
}
```

## Options

### `srcExtensions`

source extensions to resolve

**defaults:**

```json
[
  ".js",
  ".cjs",
  ".mjs",
  ".es",
  ".es6",
  ".ts",
  ".node",
  ".json"
]
```

### `dstExtension`

destination extension

**defaults:**

```json
".js"
```

### `extensionsToKeep`

extension to keep

**defaults:**

```json
[
  ".json"
]
```

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

[image-build-windows]: https://github.com/shimataro/babel-plugin-module-extension-resolver/workflows/Windows/badge.svg?event=push&branch=v1
[link-build-windows]: https://github.com/shimataro/babel-plugin-module-extension-resolver
[image-build-macos]: https://github.com/shimataro/babel-plugin-module-extension-resolver/workflows/macOS/badge.svg?event=push&branch=v1
[link-build-macos]: https://github.com/shimataro/babel-plugin-module-extension-resolver
[image-build-linux]: https://github.com/shimataro/babel-plugin-module-extension-resolver/workflows/Linux/badge.svg?event=push&branch=v1
[link-build-linux]: https://github.com/shimataro/babel-plugin-module-extension-resolver
[image-examples-check]: https://github.com/shimataro/babel-plugin-module-extension-resolver/workflows/Examples%20check/badge.svg?event=push&branch=v1
[link-examples-check]: https://github.com/shimataro/babel-plugin-module-extension-resolver
[image-release]: https://img.shields.io/github/release/shimataro/babel-plugin-module-extension-resolver.svg
[link-release]: https://github.com/shimataro/babel-plugin-module-extension-resolver/releases
[image-engine]: https://img.shields.io/node/v/babel-plugin-module-extension-resolver.svg
[link-engine]: https://nodejs.org/
[image-license]: https://img.shields.io/github/license/shimataro/babel-plugin-module-extension-resolver.svg
[link-license]: ./LICENSE

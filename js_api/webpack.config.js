const path = require("path");
const webpack = require("webpack");

const config = {
  entry: {
    index: "./src/index.ts",
    bridge: "./src/bridge.ts",
  },
  output: {
    publicPath: path.resolve(__dirname, ""),
    path: path.resolve(__dirname, "dist"),
    filename: "[name].js",
  },
  resolve: {
    extensions: [".ts", ".js", ".mjs", ".cjs", ".json"],
    fallback: {
      crypto: require.resolve("crypto-browserify"),
      stream: require.resolve("stream-browserify"),
      assert: require.resolve("assert"),
      buffer: require.resolve("buffer"),
    },
  },
  plugins: [
    new webpack.ProvidePlugin({
      process: "process/browser.js",
      Buffer: ["buffer", "Buffer"],
    }),
  ],
  module: {
    rules: [
      {
        test: /\.ts$/,
        use: "babel-loader",
        exclude: /node_modules/,
      },
      {
        test: /\.js$/,
        include: path.resolve(__dirname, "node_modules/@polkadot/"),
        use: "babel-loader",
      },
      {
        test: /\.js$/,
        include: path.resolve(__dirname, "node_modules/@acala-network/"),
        use: "babel-loader",
      },
      {
        test: /\.js$/,
        include: path.resolve(__dirname, "node_modules/@nuts-finance/"),
        use: "babel-loader",
      },
      {
        test: /\.js$/,
        include: path.resolve(__dirname, "node_modules/@polkawallet/"),
        use: "babel-loader",
      },
    ],
  },
};

module.exports = config;

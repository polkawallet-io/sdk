const path = require("path");
const webpack = require("webpack");

const config = {
  entry: "./src/index.ts",
  output: {
    publicPath: path.resolve(__dirname, ""),
    path: path.resolve(__dirname, "dist"),
    filename: "main.js",
  },
  resolve: {
    extensions: [".ts", ".js", ".mjs", ".cjs", ".json"],
    fallback: { crypto: require.resolve("crypto-browserify"), stream: require.resolve("stream-browserify") },
  },
  plugins: [
    new webpack.ProvidePlugin({
      process: "process/browser.js",
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
        test: /\.mjs$/,
        include: /node_modules/,
        type: "javascript/auto",
      },
      {
        test: /\.cjs$/,
        include: path.resolve(__dirname, "node_modules/@polkadot/"),
        use: "babel-loader",
      },
      {
        test: /\.js$/,
        include: path.resolve(__dirname, "node_modules/@polkadot/"),
        use: "babel-loader",
      },
    ],
  },
};

module.exports = config;

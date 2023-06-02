module.exports = {
  assumptions: { setPublicClassFields: true, privateFieldsAsProperties: true },
  presets: [["@babel/preset-env", { modules: false, useBuiltIns: "usage", corejs: "3.6.4" }], "@babel/preset-typescript"],
  plugins: [
    "@babel/plugin-proposal-private-methods",
    "@babel/plugin-proposal-class-properties",
    "@babel/plugin-transform-classes",
    "@babel/plugin-transform-runtime",
  ],
  sourceType: "unambiguous",
};

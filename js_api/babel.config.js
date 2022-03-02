module.exports = {
  assumptions: { setPublicClassFields: true, privateFieldsAsProperties: true },
  presets: [["@babel/preset-env", { modules: false }], "@babel/preset-typescript"],
  plugins: [
    "@babel/plugin-proposal-private-methods",
    "@babel/plugin-proposal-class-properties",
    "@babel/plugin-transform-runtime",
    "@babel/plugin-transform-classes",
    "@babel/plugin-transform-modules-commonjs",
  ],
};

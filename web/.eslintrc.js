module.exports = {
  root: true,
  env: {
    node: true,
  },
  extends: [
    'plugin:vue/essential',
    '@vue/airbnb',
    "plugin:vue/recommended",
  ],
  parserOptions: {
    parser: 'babel-eslint',
  },
  "globals": {
    "bus": false,
  },
  rules: {
    'no-console': 'off',
    'no-debugger': process.env.NODE_ENV === 'production' ? 'error' : 'off',
  },
};


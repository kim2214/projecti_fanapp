// Cloud Functions(Node 22, CommonJS)용 최소 eslint 설정 (flat config).
// 목적: 배포/런타임에서야 드러나는 오타·미정의 참조·미사용 변수를 CI에서 잡는다.
const js = require("@eslint/js");
const globals = require("globals");

module.exports = [
  {
    ignores: ["node_modules/**"],
  },
  js.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "commonjs",
      globals: {
        ...globals.node,
        // Node 18+ 전역 (globals.node 버전에 따라 누락될 수 있어 명시).
        fetch: "readonly",
        AbortController: "readonly",
      },
    },
    rules: {
      // 미사용 변수는 오류. 단, `_`로 시작하는 인자는 의도적 무시로 허용.
      "no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
      "no-undef": "error",
    },
  },
];

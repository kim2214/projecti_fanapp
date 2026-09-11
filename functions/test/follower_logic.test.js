// follower_logic.js 순수 로직 테스트 — `npm test`(node --test)로 실행.
const { test } = require("node:test");
const assert = require("node:assert/strict");
const { kstDateKey, followerCountsByKey } = require("../follower_logic");

test("kstDateKey: UTC 늦은 밤은 KST 다음 날로 넘어간다", () => {
  assert.equal(kstDateKey(new Date("2026-09-11T00:05:00Z")), "20260911");
  assert.equal(kstDateKey(new Date("2026-09-11T16:00:00Z")), "20260912");
  assert.equal(kstDateKey(new Date("2026-01-31T15:30:00Z")), "20260201");
});

const CATALOG = [
  { key: "a", broadcastId: "ch-a" },
  { key: "b", broadcastId: "ch-b" },
];

test("followerCountsByKey: 채널 ID를 멤버 key로 매핑", () => {
  const out = followerCountsByKey(CATALOG, [
    { channelId: "ch-a", followerCount: 100 },
    { channelId: "ch-b", followerCount: 0 },
  ]);
  assert.deepEqual(out, { a: 100, b: 0 });
});

test("followerCountsByKey: 카탈로그 밖 채널·비정상 값·비배열은 버린다", () => {
  const out = followerCountsByKey(CATALOG, [
    { channelId: "ch-x", followerCount: 5 },
    { channelId: "ch-a", followerCount: "137187" },
    { channelId: "ch-b", followerCount: -1 },
    null,
  ]);
  assert.deepEqual(out, {});
  assert.deepEqual(followerCountsByKey(CATALOG, undefined), {});
});

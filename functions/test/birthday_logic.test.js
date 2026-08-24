// birthday_logic.js 순수 판정 로직 테스트 — `npm test`(node --test)로 실행.
const { test } = require("node:test");
const assert = require("node:assert/strict");
const { parseMonthDay, birthdayKeysOn } = require("../birthday_logic");

test("parseMonthDay: 패딩 유무와 무관하게 파싱", () => {
  assert.deepEqual(parseMonthDay("06-15"), { month: 6, day: 15 });
  assert.deepEqual(parseMonthDay("6-15"), { month: 6, day: 15 });
  assert.deepEqual(parseMonthDay("12-01"), { month: 12, day: 1 });
});

test("parseMonthDay: 형식 오류·범위 밖이면 null", () => {
  assert.equal(parseMonthDay(null), null);
  assert.equal(parseMonthDay(615), null);
  assert.equal(parseMonthDay("06/15"), null);
  assert.equal(parseMonthDay("2026-06-15"), null);
  assert.equal(parseMonthDay("13-01"), null);
  assert.equal(parseMonthDay("06-32"), null);
  assert.equal(parseMonthDay("ab-cd"), null);
});

test("birthdayKeysOn: KST 기준 오늘 생일인 멤버만 반환", () => {
  // UTC 2026-06-15 03:00 = KST 2026-06-15 12:00
  const now = new Date(Date.UTC(2026, 5, 15, 3, 0));
  const profiles = {
    ohwayo: { birthday: "06-15" },
    ayauke: { birthday: "6-15" }, // 패딩 없는 입력도 매칭
    damyui: { birthday: "12-31" },
    mangnae: {}, // 생일 미설정
    ghost: null, // 손상 문서
  };
  assert.deepEqual(birthdayKeysOn(now, profiles), ["ohwayo", "ayauke"]);
});

test("birthdayKeysOn: UTC와 KST의 날짜가 다른 시각(자정 직후)에도 KST를 따른다", () => {
  // UTC 2026-06-14 15:30 = KST 2026-06-15 00:30 → 6/15 생일 매칭
  const now = new Date(Date.UTC(2026, 5, 14, 15, 30));
  assert.deepEqual(
    birthdayKeysOn(now, { ohwayo: { birthday: "06-15" } }),
    ["ohwayo"]
  );
  // UTC 2026-06-15 14:30 = KST 2026-06-15 23:30 → 여전히 6/15
  assert.deepEqual(
    birthdayKeysOn(new Date(Date.UTC(2026, 5, 15, 14, 30)), {
      ohwayo: { birthday: "06-15" },
    }),
    ["ohwayo"]
  );
  // UTC 2026-06-15 15:30 = KST 2026-06-16 00:30 → 6/15는 지남
  assert.deepEqual(
    birthdayKeysOn(new Date(Date.UTC(2026, 5, 15, 15, 30)), {
      ohwayo: { birthday: "06-15" },
    }),
    []
  );
});

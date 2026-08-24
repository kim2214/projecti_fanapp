// live_logic.js 순수 판정 로직 테스트 — `npm test`(node --test)로 실행.
// I/O가 없으므로 emulator·네트워크 없이 돈다 (CI functions 잡에 포함).
const { test } = require("node:test");
const assert = require("node:assert/strict");
const {
  parseLiveContent,
  nextMemberState,
  isQuietHourSkip,
} = require("../live_logic");

test("parseLiveContent: 정상 content를 집계 결과로 변환", () => {
  const r = parseLiveContent({
    status: "OPEN",
    liveTitle: "제목",
    concurrentUserCount: 1234,
    liveCategoryValue: "Just Chatting",
    openDate: "2026-08-24 20:00:00",
  });
  assert.deepEqual(r, {
    ok: true,
    status: "OPEN",
    liveTitle: "제목",
    concurrentUserCount: 1234,
    liveCategoryValue: "Just Chatting",
    openDate: "2026-08-24 20:00:00",
  });
});

test("parseLiveContent: content 없음/형식 변경이면 null — CLOSE로 오해석 금지", () => {
  assert.equal(parseLiveContent(undefined), null);
  assert.equal(parseLiveContent(null), null);
  assert.equal(parseLiveContent({}), null);
  assert.equal(parseLiveContent({ status: 123 }), null);
});

test("nextMemberState: 조회 실패면 직전 상태 유지 + 알림 없음", () => {
  const prev = { status: "OPEN", openDate: "d1", lastNotifiedOpenDate: "d1" };
  const { next, notify } = nextMemberState(prev, { ok: false });
  assert.equal(next, prev);
  assert.equal(notify, false);
});

test("nextMemberState: 새 방송(미알림 openDate)이면 알림", () => {
  const { next, notify } = nextMemberState(
    { status: "CLOSE", lastNotifiedOpenDate: "old" },
    { ok: true, status: "OPEN", openDate: "d2", liveTitle: "t" }
  );
  assert.equal(notify, true);
  // 기록은 발송 성공 후에만 index.js가 한다 — 여기선 직전 값을 그대로 넘긴다.
  assert.equal(next.lastNotifiedOpenDate, "old");
  assert.equal(next.status, "OPEN");
});

test("nextMemberState: 같은 방송(openDate)엔 재알림 없음 — 플랩/재기록 방지", () => {
  const { notify } = nextMemberState(
    { status: "CLOSE", lastNotifiedOpenDate: "d1" },
    { ok: true, status: "OPEN", openDate: "d1" }
  );
  assert.equal(notify, false);
});

test("nextMemberState: 발송 실패로 기록이 안 됐으면 다음 주기에 재시도", () => {
  // 직전 주기에 OPEN으로 기록됐지만 발송 실패 → lastNotifiedOpenDate는 null.
  const { notify } = nextMemberState(
    { status: "OPEN", openDate: "d1", lastNotifiedOpenDate: null },
    { ok: true, status: "OPEN", openDate: "d1" }
  );
  assert.equal(notify, true);
});

test("nextMemberState: openDate 없으면 알림 생략 (매 주기 재발송 방지)", () => {
  const { notify } = nextMemberState(
    {},
    { ok: true, status: "OPEN", openDate: null }
  );
  assert.equal(notify, false);
});

test("nextMemberState: CLOSE 결과는 알림 없음", () => {
  const { next, notify } = nextMemberState(
    { status: "OPEN", openDate: "d1", lastNotifiedOpenDate: "d1" },
    { ok: true, status: "CLOSE", openDate: null }
  );
  assert.equal(notify, false);
  assert.equal(next.status, "CLOSE");
  assert.equal(next.lastNotifiedOpenDate, "d1");
});

test("isQuietHourSkip: 심야(KST 04–10시)는 3분 배수 분에만 폴링", () => {
  // UTC 20:01 = KST 05:01 → 심야, 분%3!=0 → skip
  assert.equal(isQuietHourSkip(new Date(Date.UTC(2026, 0, 1, 20, 1))), true);
  // UTC 20:03 = KST 05:03 → 심야지만 분%3==0 → 폴링
  assert.equal(isQuietHourSkip(new Date(Date.UTC(2026, 0, 1, 20, 3))), false);
  // 경계: KST 04:01 → skip, KST 10:01(심야 종료 후) → 폴링
  assert.equal(isQuietHourSkip(new Date(Date.UTC(2026, 0, 1, 19, 1))), true);
  assert.equal(isQuietHourSkip(new Date(Date.UTC(2026, 0, 2, 1, 1))), false);
});

test("isQuietHourSkip: 주간(KST 14시)은 항상 폴링", () => {
  assert.equal(isQuietHourSkip(new Date(Date.UTC(2026, 0, 1, 5, 1))), false);
  assert.equal(isQuietHourSkip(new Date(Date.UTC(2026, 0, 1, 5, 3))), false);
});

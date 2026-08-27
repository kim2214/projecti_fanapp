// live_logic.js 순수 판정 로직 테스트 — `npm test`(node --test)로 실행.
// I/O가 없으므로 emulator·네트워크 없이 돈다 (CI functions 잡에 포함).
const { test } = require("node:test");
const assert = require("node:assert/strict");
const {
  parseLiveContent,
  nextMemberState,
  isQuietHourSkip,
  parseKstOpenDate,
  estimateEndedAtMs,
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

test("nextMemberState: OPEN→CLOSE면 직전 세션을 ended로 반환", () => {
  const { next, ended } = nextMemberState(
    {
      status: "OPEN",
      openDate: "d1",
      liveTitle: "제목",
      liveCategoryValue: "cat",
      peakConcurrentUserCount: 500,
    },
    { ok: true, status: "CLOSE", openDate: null }
  );
  assert.deepEqual(ended, {
    openDate: "d1",
    liveTitle: "제목",
    liveCategoryValue: "cat",
    peakConcurrentUserCount: 500,
    lastSeenLiveAt: null, // 집계에 updatedAt이 없으면 null (index.js가 now로 대체)
  });
  assert.equal(next.peakConcurrentUserCount, null);
});

test("nextMemberState: OPEN인 채 openDate가 바뀌면(즉시 재시작) 직전 세션 종료 + 새 세션 알림", () => {
  const { ended, notify, next } = nextMemberState(
    { status: "OPEN", openDate: "d1", lastNotifiedOpenDate: "d1", peakConcurrentUserCount: 300 },
    { ok: true, status: "OPEN", openDate: "d2", concurrentUserCount: 10 }
  );
  assert.equal(ended.openDate, "d1");
  assert.equal(notify, true);
  // 새 세션이므로 peak는 리셋되어 현재 시청자 수부터 다시 센다.
  assert.equal(next.peakConcurrentUserCount, 10);
});

test("nextMemberState: 같은 세션이면 peak는 누적 최대", () => {
  const { next, ended } = nextMemberState(
    { status: "OPEN", openDate: "d1", peakConcurrentUserCount: 500 },
    { ok: true, status: "OPEN", openDate: "d1", concurrentUserCount: 300 }
  );
  assert.equal(next.peakConcurrentUserCount, 500);
  assert.equal(ended, null);
});

test("nextMemberState: openDate 없던 세션은 종료돼도 기록하지 않음", () => {
  const { ended } = nextMemberState(
    { status: "OPEN", openDate: null },
    { ok: true, status: "CLOSE", openDate: null }
  );
  assert.equal(ended, null);
});

test("nextMemberState: peak 미기록(구버전 집계) 세션은 마지막 시청자 수로 폴백", () => {
  const { ended } = nextMemberState(
    { status: "OPEN", openDate: "d1", concurrentUserCount: 42 },
    { ok: true, status: "CLOSE", openDate: null }
  );
  assert.equal(ended.peakConcurrentUserCount, 42);
});

test("nextMemberState: 조회 실패 시엔 종료로 판정하지 않음", () => {
  const { ended } = nextMemberState(
    { status: "OPEN", openDate: "d1" },
    { ok: false }
  );
  assert.equal(ended, null);
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

test("nextMemberState: ended에 마지막 OPEN 관측 시각(updatedAt)을 넘긴다", () => {
  const seen = { toMillis: () => 123 };
  const { ended } = nextMemberState(
    { status: "OPEN", openDate: "d1", updatedAt: seen },
    { ok: true, status: "CLOSE", openDate: null }
  );
  assert.equal(ended.lastSeenLiveAt, seen);
});

test("parseKstOpenDate: KST 문자열을 UTC epoch ms로 (KST 20:00 = UTC 11:00)", () => {
  assert.equal(
    parseKstOpenDate("2026-08-24 20:00:00"),
    Date.UTC(2026, 7, 24, 11, 0, 0)
  );
  // KST 자정 직후는 UTC 전날
  assert.equal(
    parseKstOpenDate("2026-08-25 00:30:00"),
    Date.UTC(2026, 7, 24, 15, 30, 0)
  );
});

test("parseKstOpenDate: 형식이 다르면 null", () => {
  assert.equal(parseKstOpenDate(null), null);
  assert.equal(parseKstOpenDate(""), null);
  assert.equal(parseKstOpenDate("2026-08-24T20:00:00"), null);
  assert.equal(parseKstOpenDate("2026-08-24"), null);
});

test("estimateEndedAtMs: 마지막 OPEN 관측과 now의 중간값, 없으면 now", () => {
  assert.equal(estimateEndedAtMs(1000, 3000), 2000);
  assert.equal(estimateEndedAtMs(null, 3000), 3000);
  assert.equal(estimateEndedAtMs(undefined, 3000), 3000);
  // 시계 역행(직전 시각이 미래)이면 now로 안전 처리
  assert.equal(estimateEndedAtMs(5000, 3000), 3000);
});

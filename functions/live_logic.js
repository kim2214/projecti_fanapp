// 치지직 폴링의 순수 판정 로직 — I/O(Firestore/FCM/fetch) 없이 입력→출력만 다룬다.
// index.js에서 분리해 node --test(test/live_logic.test.js)로 검증한다.

/**
 * 치지직 polling 응답의 content를 집계용 결과로 변환한다.
 *
 * 기대 형식이 아니면(비공식 API 계약 변경 신호) null — 호출부가 실패로 취급해
 * 직전 상태를 유지한다. "CLOSE"로 오해석하면 방송 중 멤버 전원이 비방송으로
 * 덮이는 무증상 실패가 된다.
 */
function parseLiveContent(content) {
  if (!content || typeof content.status !== "string") return null;
  return {
    ok: true,
    status: content.status,
    liveTitle: content.liveTitle ?? null,
    concurrentUserCount: content.concurrentUserCount ?? null,
    // 클라 홈 대시보드 라이브 카드가 카테고리를 표시하므로 함께 집계한다.
    liveCategoryValue: content.liveCategoryValue ?? null,
    openDate: content.openDate ?? null,
  };
}

/**
 * 한 멤버의 직전 상태 + 폴링 결과 → 다음 상태와 알림 여부.
 *
 * - 조회 실패: 직전 상태를 그대로 유지, 알림 없음 (거짓 전이/알림 방지)
 * - 같은 방송(openDate)엔 1회만 알림 — 상태 플랩에도 중복 발송 방지.
 *   lastNotifiedOpenDate는 발송 "성공" 후에만 기록되므로(index.js 발송 루프),
 *   발송이 실패한 방송은 다음 주기에 자동 재시도된다.
 * - openDate가 없으면 중복 판정이 불가능해 매 주기 재발송될 수 있으므로 생략.
 */
function nextMemberState(prev, result) {
  if (!result.ok) return { next: prev, notify: false };

  const isLive = result.status === "OPEN";
  const already =
    prev.lastNotifiedOpenDate && prev.lastNotifiedOpenDate === result.openDate;

  return {
    next: {
      status: result.status,
      liveTitle: result.liveTitle,
      concurrentUserCount: result.concurrentUserCount,
      liveCategoryValue: result.liveCategoryValue,
      openDate: result.openDate,
      lastNotifiedOpenDate: prev.lastNotifiedOpenDate ?? null,
    },
    notify: Boolean(isLive && !already && result.openDate != null),
  };
}

/**
 * 심야(KST 04:00–09:59)에는 1분 스케줄 중 3분의 1만 실제 폴링한다(사실상 3분
 * 주기) — 시청이 드문 시간대에 단일 egress IP로 치지직에 11req/분을 계속 보내는
 * 밴 리스크 완화. 3분은 클라의 집계 stale 판정(5분)보다 짧아 폴백을 유발하지 않는다.
 */
function isQuietHourSkip(date) {
  const kstHour = (date.getUTCHours() + 9) % 24;
  if (kstHour < 4 || kstHour >= 10) return false;
  return date.getUTCMinutes() % 3 !== 0;
}

module.exports = { parseLiveContent, nextMemberState, isQuietHourSkip };

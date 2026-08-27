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
 * 한 멤버의 직전 상태 + 폴링 결과 → 다음 상태·알림 여부·종료된 세션.
 *
 * - 조회 실패: 직전 상태를 그대로 유지, 알림/종료 없음 (거짓 전이 방지)
 * - 같은 방송(openDate)엔 1회만 알림 — 상태 플랩에도 중복 발송 방지.
 *   lastNotifiedOpenDate는 발송 "성공" 후에만 기록되므로(index.js 발송 루프),
 *   발송이 실패한 방송은 다음 주기에 자동 재시도된다.
 * - openDate가 없으면 중복 판정이 불가능해 매 주기 재발송될 수 있으므로 생략.
 * - `ended`: OPEN이던 방송이 끝났거나(CLOSE) openDate가 바뀌면(즉시 재시작)
 *   직전 세션의 메타를 반환 — index.js가 live_history에 기록한다.
 *   openDate가 없던 세션은 식별/중복 방지가 불가능해 기록하지 않는다.
 * - `peakConcurrentUserCount`: 같은 세션(openDate) 동안의 최고 동시 시청자.
 *   새 세션이면 리셋, 종료 기록에 쓰인다.
 */
function nextMemberState(prev, result) {
  if (!result.ok) return { next: prev, notify: false, ended: null };

  const isLive = result.status === "OPEN";
  const wasLive = prev.status === "OPEN";
  const sameSession = isLive && wasLive && prev.openDate === result.openDate;
  const already =
    prev.lastNotifiedOpenDate && prev.lastNotifiedOpenDate === result.openDate;

  const ended =
    wasLive && !sameSession && prev.openDate
      ? {
          openDate: prev.openDate,
          liveTitle: prev.liveTitle ?? null,
          liveCategoryValue: prev.liveCategoryValue ?? null,
          // 구버전 집계(peak 미기록)와의 호환: 마지막 시청자 수로 폴백.
          peakConcurrentUserCount:
            prev.peakConcurrentUserCount ?? prev.concurrentUserCount ?? null,
          // 마지막으로 OPEN을 본 시각(집계 updatedAt) — 종료 시각 추정에 쓴다.
          lastSeenLiveAt: prev.updatedAt ?? null,
        }
      : null;

  return {
    next: {
      status: result.status,
      liveTitle: result.liveTitle,
      concurrentUserCount: result.concurrentUserCount,
      liveCategoryValue: result.liveCategoryValue,
      openDate: result.openDate,
      lastNotifiedOpenDate: prev.lastNotifiedOpenDate ?? null,
      peakConcurrentUserCount: isLive
        ? Math.max(
            sameSession ? (prev.peakConcurrentUserCount ?? 0) : 0,
            result.concurrentUserCount ?? 0
          )
        : null,
    },
    notify: Boolean(isLive && !already && result.openDate != null),
    ended,
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

/**
 * 치지직 openDate("yyyy-MM-dd HH:mm:ss", KST)를 epoch ms로 변환한다.
 * 형식이 다르면 null. 클라가 문자열을 기기 로컬로 해석하면 해외 사용자에게
 * 방송 길이가 시차만큼 틀어지므로, 서버가 절대 시각(Timestamp)으로 저장한다.
 */
function parseKstOpenDate(openDate) {
  const m = /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/.exec(
    openDate ?? ""
  );
  if (!m) return null;
  const [, y, mo, d, h, mi, sec] = m.map(Number);
  return Date.UTC(y, mo - 1, d, h, mi, sec) - 9 * 60 * 60 * 1000;
}

/**
 * 종료 시각 추정(epoch ms). 실제 종료는 "마지막으로 OPEN을 본 폴링"과
 * "CLOSE를 처음 본 폴링(now)" 사이 어딘가이므로 중간값을 쓴다 — 오차가
 * 폴링 주기의 절반(±30초, 심야 ±90초)으로 줄어든다. 직전 시각이 없으면 now.
 */
function estimateEndedAtMs(lastSeenLiveMs, nowMs) {
  if (typeof lastSeenLiveMs !== "number" || lastSeenLiveMs > nowMs) return nowMs;
  return Math.round((lastSeenLiveMs + nowMs) / 2);
}

module.exports = {
  parseLiveContent,
  nextMemberState,
  isQuietHourSkip,
  parseKstOpenDate,
  estimateEndedAtMs,
};

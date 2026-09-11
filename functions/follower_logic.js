// 팔로워 수 일별 기록의 순수 로직 — I/O 없이 입력→출력만 다룬다.
// index.js(recordFollowerCounts)에서 사용하고 test/follower_logic.test.js로 검증한다.

/**
 * 주어진 시각(UTC Date)의 KST 날짜를 "yyyyMMdd"로 돌려준다 — 일별 문서 ID.
 * 같은 날 재실행돼도 같은 ID로 덮어써 중복 문서가 생기지 않는다.
 */
function kstDateKey(date) {
  const kst = new Date(date.getTime() + 9 * 60 * 60 * 1000);
  const y = kst.getUTCFullYear();
  const m = String(kst.getUTCMonth() + 1).padStart(2, "0");
  const d = String(kst.getUTCDate()).padStart(2, "0");
  return `${y}${m}${d}`;
}

/**
 * 치지직 Open API 채널 조회 응답(content.data 배열)을 멤버 key → followerCount
 * 맵으로 바꾼다. 카탈로그에 없는 채널, followerCount가 숫자가 아닌 항목은 버린다
 * (응답 형식 변경 시 잘못된 값이 기록되지 않게).
 */
function followerCountsByKey(catalog, apiData) {
  const keyByChannel = new Map(catalog.map((m) => [m.broadcastId, m.key]));
  const out = {};
  for (const item of Array.isArray(apiData) ? apiData : []) {
    const key = keyByChannel.get(item?.channelId);
    if (!key) continue;
    if (!Number.isInteger(item.followerCount) || item.followerCount < 0) continue;
    out[key] = item.followerCount;
  }
  return out;
}

module.exports = { kstDateKey, followerCountsByKey };

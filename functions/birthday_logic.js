// 생일 푸시의 순수 판정 로직 — I/O 없이 입력→출력만 다룬다.
// index.js(birthdayPush)에서 사용하고 test/birthday_logic.test.js로 검증한다.

/**
 * "MM-DD" 문자열을 {month, day}로 파싱한다. 형식이 잘못되면 null.
 * 클라(StreamerModel._monthDay)와 같은 검증 규칙 — "6-15"처럼 패딩 없는
 * 값도 허용해 콘솔 입력 편차에 견딘다.
 */
function parseMonthDay(raw) {
  if (typeof raw !== "string") return null;
  const parts = raw.split("-");
  if (parts.length !== 2) return null;
  const month = Number(parts[0]);
  const day = Number(parts[1]);
  if (!Number.isInteger(month) || !Number.isInteger(day)) return null;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  return { month, day };
}

/**
 * 주어진 시각(UTC Date) 기준 KST 날짜가 생일인 멤버 key 목록을 반환한다.
 * profiles: {key: {birthday: "MM-DD", ...}} (Firestore 프로필 문서들).
 */
function birthdayKeysOn(date, profiles) {
  const kst = new Date(date.getTime() + 9 * 60 * 60 * 1000);
  const month = kst.getUTCMonth() + 1;
  const day = kst.getUTCDate();
  return Object.entries(profiles)
    .filter(([, p]) => {
      const md = parseMonthDay(p && p.birthday);
      return md !== null && md.month === month && md.day === day;
    })
    .map(([key]) => key);
}

module.exports = { parseMonthDay, birthdayKeysOn };

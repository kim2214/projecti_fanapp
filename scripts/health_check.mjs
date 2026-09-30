// 서버(Cloud Functions) 멈춤 감지 — GitHub Actions(.github/workflows/health.yml)가 주기 실행한다.
//
// 빌링 중단 등으로 Functions가 멈추면 GCP 안의 알림도 함께 멈출 수 있어, GCP 밖에서
// Firestore 공개 읽기(REST, 자격 증명 불필요 — firestore.rules가 read: true)로 서버가
// 남긴 흔적의 신선도를 본다. 문제가 있으면 exit 1 → 워크플로 실패 → GitHub 메일 알림.
//
// 로컬 실행: node scripts/health_check.mjs

const BASE =
  "https://firestore.googleapis.com/v1/projects/honeyzfanapp/databases/(default)/documents";

// pollLiveStatus는 1분(심야 3분) 주기지만, 429 백오프 중엔 10분간 집계를 쓰지 않는다.
const LIVE_STALE_MS = 20 * 60 * 1000;
// functions/index.js pollLiveStatus가 error로 승격하는 기준과 같다.
const ALL_FAILURE_THRESHOLD = 5;
// recordFollowerCounts는 매일 KST 09:05. 여유를 두고 10시부터 오늘 기록을 기대한다.
const FOLLOWER_EXPECT_KST_HOUR = 10;
// 배치 쓰기라 멤버 전원이 함께 기록되므로 한 명만 본다.
const FOLLOWER_PROBE_MEMBER = "honeychurros";

async function getDoc(path) {
  const res = await fetch(`${BASE}/${path}`, { signal: AbortSignal.timeout(15000) });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`${path}: HTTP ${res.status}`);
  return (await res.json()).fields ?? {};
}

/** KST 날짜 "yyyyMMdd" — functions/follower_logic.js kstDateKey와 같은 규칙. */
function kstDateKey(ms) {
  return new Date(ms + 9 * 60 * 60 * 1000).toISOString().slice(0, 10).replace(/-/g, "");
}

const minutesAgo = (ms, now) => `${Math.round((now - ms) / 60000)}분 전`;

async function checkLiveStatus(now) {
  const f = await getDoc("live_status/current");
  if (!f) return ["live_status/current 문서 없음"];
  const problems = [];
  const updatedMs = Date.parse(f.updatedAt?.timestampValue ?? "");
  if (Number.isNaN(updatedMs)) {
    problems.push("live_status/current.updatedAt 없음");
  } else if (now - updatedMs > LIVE_STALE_MS) {
    problems.push(
      `pollLiveStatus 멈춤 의심 — 집계 마지막 갱신 ${f.updatedAt.timestampValue} (${minutesAgo(updatedMs, now)})`
    );
  }
  const failures = Number(f.consecutiveAllFailures?.integerValue ?? 0);
  if (failures >= ALL_FAILURE_THRESHOLD) {
    problems.push(`치지직 폴링 전원 실패 ${failures}회 연속 — 차단/응답 형식 변경 의심`);
  }
  return problems;
}

async function checkFollowerHistory(now) {
  const kstHour = new Date(now + 9 * 60 * 60 * 1000).getUTCHours();
  const dayMs = 24 * 60 * 60 * 1000;
  const expected = kstDateKey(kstHour >= FOLLOWER_EXPECT_KST_HOUR ? now : now - dayMs);
  const f = await getDoc(`follower_history/${FOLLOWER_PROBE_MEMBER}/daily/${expected}`);
  return f ? [] : [`recordFollowerCounts 기록 없음 — follower_history/${FOLLOWER_PROBE_MEMBER}/daily/${expected}`];
}

const now = Date.now();
const results = await Promise.allSettled([checkLiveStatus(now), checkFollowerHistory(now)]);
const problems = results.flatMap((r) =>
  r.status === "fulfilled" ? r.value : [`점검 요청 실패: ${r.reason?.message ?? r.reason}`]
);

if (problems.length === 0) {
  console.log("OK — pollLiveStatus·recordFollowerCounts 정상");
} else {
  for (const p of problems) console.error(`::error::${p}`);
  process.exitCode = 1;
}

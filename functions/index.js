const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();

// 멤버 정적 카탈로그 — lib/controllers/global_controller.dart 의 Member 카탈로그와
// 반드시 동기화한다 (key/name/group/broadcastId). add-member skill 참고.
const MEMBER_CATALOG = [
  { key: "honeychurros", name: "허니츄러스",     group: "honeyz", broadcastId: "c0d9723cbb75dc223c6aa8a9d4f56002" },
  { key: "ayauke",       name: "아야",           group: "honeyz", broadcastId: "abe8aa82baf3d3ef54ad8468ee73e7fc" },
  { key: "damyui",       name: "담유이",         group: "honeyz", broadcastId: "b82e8bc2505e37156b2d1140ba1fc05c" },
  { key: "ddddragon",    name: "디디디용",       group: "honeyz", broadcastId: "798e100206987b59805cfb75f927e965" },
  { key: "ohwayo",       name: "오화요",         group: "honeyz", broadcastId: "65a53076fe1a39636082dd6dba8b8a4b" },
  { key: "mangnae",      name: "망내",           group: "honeyz", broadcastId: "bd07973b6021d72512240c01a386d5c9" },
  { key: "popopopo",     name: "포포포포",       group: "acaxia", broadcastId: "3e3781d3bd20dadc2f6f6d5d30091195" },
  { key: "violetaMone",  name: "비올레타 모네",  group: "acaxia", broadcastId: "5c897b3e639045ca6e314bbaff991f73" },
  { key: "blaireRose",   name: "블레어 로즈",    group: "acaxia", broadcastId: "dae2de8eaa005a59163f2e4c045e1aa1" },
  { key: "hasiyo",       name: "하시요",         group: "acaxia", broadcastId: "b33c957eac9335d38e4043c3dca97675" },
  { key: "ryushiho",     name: "류시호",         group: "acaxia", broadcastId: "f36320c432d9f06095ce2cfbbf681c26" },
];

// 멤버 key → 표시 이름 (카탈로그에서 파생 — 스케줄 푸시가 사용)
const MEMBER_NAMES = Object.fromEntries(MEMBER_CATALOG.map((m) => [m.key, m.name]));

const GROUP_LABELS = {
  honeyz: "허니즈",
  acaxia: "아카시아",
};

/**
 * 스케줄 문서 쓰기 이벤트를 받아, schedule_image가 실제로 새로 들어왔거나
 * 바뀐 경우에만 해당 그룹 토픽으로 푸시를 보낸다.
 */
async function handleScheduleWrite(group, event) {
  const beforeData = event.data.before.exists ? event.data.before.data() : null;
  const afterData = event.data.after.exists ? event.data.after.data() : null;

  // 문서 삭제는 무시
  if (!afterData) return;

  const url = afterData.schedule_image;
  // 빈 값(미등록 상태)은 알림 대상 아님
  if (!url) return;

  // schedule_image가 직전과 동일하면(다른 필드만 수정/재저장) 중복 발송 방지
  if (beforeData && beforeData.schedule_image === url) return;

  const memberKey = event.params.memberKey;
  const memberName = MEMBER_NAMES[memberKey] || "멤버";
  const groupLabel = GROUP_LABELS[group] || "";

  try {
    await getMessaging().send({
      topic: `schedule_${group}`,
      notification: {
        title: `${groupLabel} 스케줄 업데이트`,
        body: `${memberName} 이번 주 스케줄이 올라왔어요!`,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "schedule_channel",
        },
      },
    });
    console.log(`schedule push sent: group=${group} member=${memberKey}`);
  } catch (err) {
    console.error(`schedule push failed: group=${group} member=${memberKey}`, err);
  }
}

exports.onHoneyzScheduleWrite = onDocumentWritten(
  { document: "schedule/{memberKey}", region: "asia-northeast3" },
  (event) => handleScheduleWrite("honeyz", event)
);

exports.onAcaxiaScheduleWrite = onDocumentWritten(
  { document: "schedule_acaxia/{memberKey}", region: "asia-northeast3" },
  (event) => handleScheduleWrite("acaxia", event)
);

// ─────────────────────────────────────────────────────────────────────────
// 서버측 라이브 폴링 → CLOSE→OPEN 전이 시 멤버별 토픽으로 방송 시작 푸시.
//
// 치지직은 비공식 polling 엔드포인트라, 이 함수가 유일한 백그라운드 라이브
// 감지 경로다. 클라 포그라운드 폴링(GlobalController)은 폴백으로 유지된다.
// ─────────────────────────────────────────────────────────────────────────

const CHZZK_TIMEOUT_MS = 8000;

/**
 * 단일 멤버의 라이브 상태 조회. 실패 시 { ok: false }.
 * 타임아웃/네트워크 등 일시적 오류는 조용히 실패 처리하고, 호출부에서 직전
 * 상태를 유지해 거짓 CLOSE→OPEN 알림을 막는다.
 */
async function fetchLiveStatus(broadcastId) {
  const url = `https://api.chzzk.naver.com/polling/v2/channels/${broadcastId}/live-status`;
  const ac = new AbortController();
  const timer = setTimeout(() => ac.abort(), CHZZK_TIMEOUT_MS);
  try {
    const res = await fetch(url, {
      signal: ac.signal,
      // 클라우드 기본 UA는 봇처럼 보일 수 있어 브라우저 UA를 지정 (치지직 한정).
      headers: { "User-Agent": "Mozilla/5.0", Accept: "application/json" },
    });
    if (res.status !== 200) {
      console.warn(`chzzk live-status HTTP ${res.status}: ${broadcastId}`);
      return { ok: false };
    }
    const content = (await res.json()).content || {};
    return {
      ok: true,
      status: content.status ?? "CLOSE",
      liveTitle: content.liveTitle ?? null,
      concurrentUserCount: content.concurrentUserCount ?? null,
      openDate: content.openDate ?? null,
    };
  } catch (e) {
    console.warn(`chzzk fetch failed: ${broadcastId} (${e.message})`);
    return { ok: false };
  } finally {
    clearTimeout(timer);
  }
}

exports.pollLiveStatus = onSchedule(
  {
    schedule: "every 1 minutes",
    timeZone: "Asia/Seoul",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
    maxInstances: 1, // 겹쳐 실행되지 않게 단일 인스턴스로 제한
  },
  async () => {
    const db = getFirestore();
    const ref = db.doc("live_status/current");
    const prev = (await ref.get()).data()?.members || {};

    const results = await Promise.all(
      MEMBER_CATALOG.map(async (m) => ({ m, r: await fetchLiveStatus(m.broadcastId) }))
    );

    const nextMembers = {};
    const toNotify = [];

    for (const { m, r } of results) {
      const p = prev[m.key] || {};

      // 조회 실패: 직전 상태를 그대로 유지 (거짓 전이/알림 방지)
      if (!r.ok) {
        nextMembers[m.key] = p;
        continue;
      }

      const wasLive = p.status === "OPEN";
      const isLive = r.status === "OPEN";
      // 같은 방송(openDate)으로는 한 번만 알림 → 상태 플랩에도 중복 발송 방지
      const already = p.lastNotifiedOpenDate && p.lastNotifiedOpenDate === r.openDate;
      const shouldNotify = isLive && !wasLive && !already;

      nextMembers[m.key] = {
        status: r.status,
        liveTitle: r.liveTitle,
        concurrentUserCount: r.concurrentUserCount,
        openDate: r.openDate,
        lastNotifiedOpenDate: shouldNotify ? r.openDate : (p.lastNotifiedOpenDate ?? null),
        updatedAt: FieldValue.serverTimestamp(),
      };

      if (shouldNotify) toNotify.push({ m, r });
    }

    // 11명 상태를 집계 문서 1개에 한 번에 기록 (주기당 읽기1 + 쓰기1)
    await ref.set(
      { members: nextMembers, updatedAt: FieldValue.serverTimestamp() },
      { merge: true }
    );

    for (const { m, r } of toNotify) {
      try {
        await getMessaging().send({
          topic: `live_${m.key}`,
          notification: {
            title: `${m.name} 방송 시작!`,
            body: r.liveTitle || "지금 라이브 중이에요",
          },
          data: { type: "live", broadcastId: m.broadcastId, memberKey: m.key },
          android: {
            priority: "high",
            notification: { channelId: "live_channel" },
          },
        });
        console.log(`live push sent: ${m.key}`);
      } catch (err) {
        console.error(`live push failed: ${m.key}`, err);
      }
    }
  }
);

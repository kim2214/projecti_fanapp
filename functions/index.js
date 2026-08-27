const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const {
  parseLiveContent,
  nextMemberState,
  isQuietHourSkip,
  parseKstOpenDate,
  estimateEndedAtMs,
} = require("./live_logic");
const { birthdayKeysOn } = require("./birthday_logic");

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
// 서버측 라이브 폴링 → 아직 알림을 보내지 않은 방송(openDate 기준)이 OPEN이면
// 멤버별 토픽으로 방송 시작 푸시.
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
      // httpStatus는 호출부의 429/403(밴 의심) 백오프 판정에 쓰인다.
      console.warn(`chzzk live-status HTTP ${res.status}: ${broadcastId}`);
      return { ok: false, httpStatus: res.status };
    }
    // 200인데 기대 형식이 아니면(비공식 API 계약 변경 신호) 실패로 처리해 직전
    // 상태를 유지한다 — 판정은 live_logic.parseLiveContent(순수, 테스트 대상).
    const parsed = parseLiveContent((await res.json()).content);
    if (!parsed) {
      console.error(`chzzk live-status 형식 변경 의심 (content.status 없음): ${broadcastId}`);
      return { ok: false };
    }
    return parsed;
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
    // 심야(KST 04–10시)는 3분 주기로 완화한다 — live_logic.isQuietHourSkip 참고.
    if (isQuietHourSkip(new Date())) return;

    const db = getFirestore();
    const ref = db.doc("live_status/current");
    const doc = (await ref.get()).data() || {};
    const prev = doc.members || {};

    // 429/403(밴 의심) 감지 후 백오프 중이면 이번 주기는 쉰다 — 집계 문서가
    // 오래되면(5분) 클라가 직접 폴링으로 폴백하므로 화면 표시는 유지된다.
    if (typeof doc.rateLimitedUntil === "number" && doc.rateLimitedUntil > Date.now()) {
      console.warn(`chzzk 백오프 중 (~${new Date(doc.rateLimitedUntil).toISOString()}) — 주기 생략`);
      return;
    }

    const results = await Promise.all(
      MEMBER_CATALOG.map(async (m) => ({ m, r: await fetchLiveStatus(m.broadcastId) }))
    );

    // 다음 상태·알림·종료 판정은 live_logic.nextMemberState(순수 함수, 테스트 대상).
    const nextMembers = {};
    const toNotify = [];
    const endedSessions = [];
    for (const { m, r } of results) {
      const { next, notify, ended } = nextMemberState(prev[m.key] || {}, r);
      // 성공 조회만 갱신 시각을 새로 찍는다 (실패는 직전 상태 그대로 유지).
      nextMembers[m.key] = r.ok
        ? { ...next, updatedAt: FieldValue.serverTimestamp() }
        : next;
      if (notify) toNotify.push({ m, r });
      if (ended) endedSessions.push({ m, ended });
    }

    // 관측성: warn만으로는 폴링이 몇 시간 죽어도 아무도 모른다. 429/403과
    // 전원 실패 지속은 error로 승격해 Cloud Logging 알림 정책에 걸리게 한다.
    const rateLimited = results.some(
      ({ r }) => r.httpStatus === 429 || r.httpStatus === 403
    );
    const consecutiveAllFailures = results.every(({ r }) => !r.ok)
      ? (doc.consecutiveAllFailures || 0) + 1
      : 0;
    if (rateLimited) {
      console.error("chzzk 429/403 감지 — 10분 백오프 진입 (밴 의심)");
    }
    if (consecutiveAllFailures >= 5) {
      console.error(
        `chzzk 폴링 전원 실패 ${consecutiveAllFailures}회 연속 — 차단/계약 변경 의심`
      );
    }

    // 발송을 집계 기록보다 먼저 수행하고, 성공한 방송만 lastNotifiedOpenDate에
    // 남긴다. 기록을 먼저 하면 발송이 한 번 실패했을 때 영영 재시도되지 않는다.
    // (기록 전에 함수가 죽으면 다음 주기에 중복 발송될 수 있으나, 누락보다 낫다.)
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
        nextMembers[m.key].lastNotifiedOpenDate = r.openDate;
      } catch (err) {
        console.error(`live push failed: ${m.key}`, err);
      }
    }

    // 종료된 방송 세션을 live_history/{memberKey}/sessions/{id}에 기록한다
    // (클라 멤버 프로필의 "지난 방송" 목록). 문서 ID를 openDate에서 파생해
    // 재실행돼도 같은 세션이 중복 생성되지 않는다. 베스트 에포트 — 기록이
    // 실패해도 집계 쓰기는 진행한다(다음 주기에 전이가 소진돼 그 세션만 유실).
    for (const { m, ended } of endedSessions) {
      try {
        const sessionId = ended.openDate.replace(/\D/g, "");
        const startedMs = parseKstOpenDate(ended.openDate);
        // 집계에서 읽은 updatedAt은 Firestore Timestamp(toMillis) — 없으면 now.
        const lastSeenMs =
          typeof ended.lastSeenLiveAt?.toMillis === "function"
            ? ended.lastSeenLiveAt.toMillis()
            : null;
        await db.doc(`live_history/${m.key}/sessions/${sessionId}`).set({
          liveTitle: ended.liveTitle,
          liveCategoryValue: ended.liveCategoryValue,
          openDate: ended.openDate,
          // 절대 시각(Timestamp) — 클라가 기기 타임존과 무관하게 계산할 수 있게.
          startedAt: startedMs != null ? Timestamp.fromMillis(startedMs) : null,
          peakConcurrentUserCount: ended.peakConcurrentUserCount,
          // 마지막 OPEN 관측과 CLOSE 관측의 중간값 (±폴링 주기/2 오차).
          endedAt: Timestamp.fromMillis(estimateEndedAtMs(lastSeenMs, Date.now())),
        });
        console.log(`live session recorded: ${m.key} ${sessionId}`);
      } catch (err) {
        console.error(`live session record failed: ${m.key}`, err);
      }
    }

    // 11명 상태를 집계 문서 1개에 한 번에 기록 (주기당 읽기1 + 쓰기1).
    // merge 없이 통째로 교체한다 — merge:true면 map이 깊은 병합되어, 카탈로그에서
    // 뺀 멤버의 옛 상태(OPEN 가능)가 문서에 영구 잔존한다.
    await ref.set({
      members: nextMembers,
      updatedAt: FieldValue.serverTimestamp(),
      consecutiveAllFailures,
      rateLimitedUntil: rateLimited ? Date.now() + 10 * 60 * 1000 : null,
    });
  }
);

// ─────────────────────────────────────────────────────────────────────────
// 생일 푸시 — 매일 KST 09:00에 Firestore 프로필의 birthday("MM-DD")가 오늘인
// 멤버를 찾아 그룹 토픽으로 발송한다.
//
// 별도 토픽/채널 없이 기존 schedule_{group} 토픽·schedule_channel 채널을
// 재사용한다 — 클라 변경 없이 현재 설치된 앱에도 즉시 동작하고, 그룹 알림을
// 끈 사용자에게는 가지 않는다(설정 일관성). 하루 1회 스케줄(재시도 없음)이라
// 별도 중복 방지 기록은 두지 않는다.
// ─────────────────────────────────────────────────────────────────────────

exports.birthdayPush = onSchedule(
  {
    schedule: "0 9 * * *",
    timeZone: "Asia/Seoul",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
    maxInstances: 1,
  },
  async () => {
    const db = getFirestore();

    for (const group of ["honeyz", "acaxia"]) {
      // 스트리머 컬렉션 이름은 그룹 이름과 동일 (firestore-data skill 참고).
      const snapshot = await db.collection(group).get();
      const profiles = {};
      snapshot.forEach((doc) => (profiles[doc.id] = doc.data()));

      for (const key of birthdayKeysOn(new Date(), profiles)) {
        // 카탈로그에 없는 key(탈퇴/오타 문서)는 발송하지 않는다.
        const name = MEMBER_NAMES[key];
        if (!name) continue;

        try {
          await getMessaging().send({
            topic: `schedule_${group}`,
            notification: {
              title: `오늘은 ${name} 생일! 🎂`,
              body: `${GROUP_LABELS[group]} ${name}에게 축하를 보내주세요 🎉`,
            },
            android: {
              priority: "high",
              notification: { channelId: "schedule_channel" },
            },
          });
          console.log(`birthday push sent: ${group}/${key}`);
        } catch (err) {
          console.error(`birthday push failed: ${group}/${key}`, err);
        }
      }
    }
  }
);

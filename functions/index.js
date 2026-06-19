const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

// 멤버 key → 표시 이름 (lib/controllers/global_controller.dart 카탈로그와 동기화)
const MEMBER_NAMES = {
  // honeyz
  honeychurros: "허니츄러스",
  ayauke: "아야",
  damyui: "담유이",
  ddddragon: "디디디용",
  ohwayo: "오화요",
  mangnae: "망내",
  // acaxia
  popopopo: "포포포포",
  violetaMone: "비올레타 모네",
  blaireRose: "블레어 로즈",
  hasiyo: "하시요",
  ryushiho: "류시호",
};

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

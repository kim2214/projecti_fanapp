// ScheduleModel 파싱 — 콘솔에서 잘못된 타입을 넣어도 로드 전체가 실패하지 않아야 한다.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/model/schedule_model.dart';
import 'package:projecti_fan_app/widget/schedule_page.dart';

void main() {
  test('schedule_image 문자열을 그대로 읽는다', () {
    expect(
        ScheduleModel.fromJson({'schedule_image': 'https://x/a.png'})
            .scheduleURL,
        'https://x/a.png');
  });

  test('문자열이 아니거나 없으면 null', () {
    expect(ScheduleModel.fromJson({'schedule_image': 123}).scheduleURL, isNull);
    expect(ScheduleModel.fromJson(const {}).scheduleURL, isNull);
  });

  test('schedule_updated_at Timestamp를 등록 시각으로 읽고, 없거나 다른 타입이면 null', () {
    final at = DateTime(2026, 11, 18, 21, 49);
    expect(
        ScheduleModel.fromJson({
          'schedule_image': 'https://x/a.png',
          'schedule_updated_at': Timestamp.fromDate(at),
        }).updatedAt,
        at);
    expect(
        ScheduleModel.fromJson({'schedule_image': 'https://x/a.png'}).updatedAt,
        isNull);
    expect(
        ScheduleModel.fromJson({'schedule_updated_at': '2026-11-18'}).updatedAt,
        isNull);
  });

  test('카드 상태 문구: 등록 전 / 날짜 없는 등록 / 날짜 있는 등록', () {
    final now = DateTime(2026, 11, 23);
    expect(ScheduleCard.statusLabel(hasSchedule: false), '스케줄 등록 전');
    // 이미지를 비운 뒤 남은 예전 시각은 무시한다.
    expect(
        ScheduleCard.statusLabel(
            hasSchedule: false, registeredAt: DateTime(2026, 11, 18), now: now),
        '스케줄 등록 전');
    expect(ScheduleCard.statusLabel(hasSchedule: true), '스케줄 등록됨');
    expect(
        ScheduleCard.statusLabel(
            hasSchedule: true, registeredAt: DateTime(2026, 11, 18), now: now),
        '11/18 등록');
  });
}

// 팔로워 기록 한 점 파싱 — 문서 ID "yyyyMMdd" + followerCount 필드에서 만든다.
// 손상된 문서는 null로 건너뛰어 차트가 깨지지 않게 한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/model/follower_point_model.dart';

void main() {
  test('정상 문서 파싱', () {
    final p = FollowerPointModel.fromDoc('20261018', {'followerCount': 12345});
    expect(p, isNotNull);
    expect(p!.date, DateTime(2026, 10, 18));
    expect(p.followerCount, 12345);
  });

  test('num(double)도 정수로 변환', () {
    final p = FollowerPointModel.fromDoc('20260101', {'followerCount': 100.0});
    expect(p!.followerCount, 100);
  });

  test('ID 길이가 8이 아니면 null', () {
    expect(FollowerPointModel.fromDoc('2026101', {'followerCount': 1}), isNull);
    expect(
        FollowerPointModel.fromDoc('202610180', {'followerCount': 1}), isNull);
  });

  test('ID에 숫자 아닌 부분이 있으면 null', () {
    expect(FollowerPointModel.fromDoc('2026XX18', {'followerCount': 1}), isNull);
  });

  test('followerCount가 없거나 숫자가 아니면 null', () {
    expect(FollowerPointModel.fromDoc('20261018', {}), isNull);
    expect(FollowerPointModel.fromDoc('20261018', {'followerCount': 'abc'}),
        isNull);
    expect(FollowerPointModel.fromDoc('20261018', {'followerCount': null}),
        isNull);
  });
}

// ScheduleModel 파싱 — 콘솔에서 잘못된 타입을 넣어도 로드 전체가 실패하지 않아야 한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/model/schedule_model.dart';

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
}

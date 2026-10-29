// 스케줄 이미지 저장·공유의 순수 부분(형식 판별·파일 이름) 테스트.
// 갤러리·공유 시트 호출은 플랫폼 채널이라 실기기에서 확인한다.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/utils/schedule_image.dart';

void main() {
  group('imageExtensionOf', () {
    Uint8List bytes(List<int> head) =>
        Uint8List.fromList([...head, ...List.filled(16, 0)]);

    test('시그니처로 png·gif·webp·jpg를 고른다', () {
      expect(imageExtensionOf(bytes([0x89, 0x50, 0x4E, 0x47])), 'png');
      expect(imageExtensionOf(bytes([0x47, 0x49, 0x46, 0x38])), 'gif');
      expect(
          imageExtensionOf(bytes([
            0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, //
            0x57, 0x45, 0x42, 0x50,
          ])),
          'webp');
      expect(imageExtensionOf(bytes([0xFF, 0xD8, 0xFF])), 'jpg');
    });

    test('모르는 형식·짧은 데이터는 jpg', () {
      expect(imageExtensionOf(Uint8List(0)), 'jpg');
      expect(imageExtensionOf(Uint8List.fromList([0x89])), 'jpg');
      // RIFF지만 WEBP가 아님 (예: WAV)
      expect(
          imageExtensionOf(bytes([
            0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, //
            0x57, 0x41, 0x56, 0x45,
          ])),
          'jpg');
    });
  });

  group('scheduleImageBaseName', () {
    final now = DateTime(2026, 3, 5);

    test('멤버 이름 + 날짜(YYMMDD)', () {
      expect(scheduleImageBaseName('오화요', now), '오화요_스케줄_260305');
    });

    test('파일 이름에 못 쓰는 문자·공백은 _로, 빈 이름은 날짜만', () {
      expect(scheduleImageBaseName('a/b c', now), 'a_b_c_스케줄_260305');
      expect(scheduleImageBaseName('  ', now), '스케줄_260305');
    });
  });
}

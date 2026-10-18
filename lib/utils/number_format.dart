/// 천 단위 쉼표 표기 (예: 1384 → "1,384"). 시청자 수·팔로워 수 표시에 공통 사용.
String formatCount(int count) => count.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

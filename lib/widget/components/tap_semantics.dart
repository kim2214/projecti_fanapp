import 'package:flutter/material.dart';

/// GestureDetector 기반 탭 요소를 스크린리더가 하나의 "버튼"으로 읽게 한다.
///
/// GestureDetector는 시맨틱을 만들지 않아 TalkBack이 탭 가능 여부를 알 수 없고,
/// 카드 안의 텍스트들이 각각 별개 노드로 읽힌다. 자식 노드를 하나로 합치고
/// (MergeSemantics) 버튼 역할을 부여한다. 아이콘만 있는 요소는 [label]을 준다.
class TapSemantics extends StatelessWidget {
  final String? label;
  final bool? selected;
  final Widget child;

  const TapSemantics({
    super.key,
    this.label,
    this.selected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: label,
        selected: selected,
        child: child,
      ),
    );
  }
}

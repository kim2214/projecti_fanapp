import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/bindings.dart';
import 'package:projecti_fan_app/model/streamer_model.dart';
import 'package:projecti_fan_app/widget/components/schedule_detail.dart';
import 'package:projecti_fan_app/widget/components/streamer_detail.dart';
import 'package:projecti_fan_app/widget/group_select_widget.dart';
import 'package:projecti_fan_app/widget/live_page.dart';
import 'package:projecti_fan_app/widget/screen_base_widget.dart';
import 'package:projecti_fan_app/widget/splash_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        BindingClass().dependencies();
        return const SplashScreen();
      },
    ),
    GoRoute(
      path: '/groupSelect',
      builder: (context, state) {
        return const GroupSelectWidget();
      },
    ),
    GoRoute(
      path: '/baseScreen',
      builder: (context, state) {
        return const ScreenBaseWidget();
      },
    ),
    GoRoute(
      path: '/livePage',
      builder: (context, state) {
        return const LivePageWidget();
      },
    ),
    GoRoute(
      path: '/scheduleDetail',
      builder: (context, state) {
        // 인자는 extra로 받는다 ([ScheduleDetailArgs] 참고). extra가 없는 진입
        // (복원·딥링크)에서도 null 단언으로 죽지 않고 안내 화면을 보여준다.
        final args = state.extra as ScheduleDetailArgs?;
        return ScheduleDetail(
          imageURL: args?.imageURL,
          name: args?.name,
        );
      },
    ),
    GoRoute(
      path: '/streamerDetail',
      builder: (context, state) {
        // extra가 없는 진입(상태 복원·딥링크)에서도 널 캐스트로 죽지 않는다.
        // 프로필 이미지·영상은 group/key(쿼리)에서 파생되므로 빈 모델로도 그려진다.
        final pjiMember = (state.extra as StreamerModel?) ?? StreamerModel.empty();
        final group = state.uri.queryParameters['group'] ?? 'honeyz';
        final memberKey = state.uri.queryParameters['key'] ?? '';
        return StreamerDetail(
          pjiMember: pjiMember,
          group: group,
          memberKey: memberKey,
        );
      },
    ),
  ],
);

import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/model/group.dart';
import 'package:projecti_fan_app/widget/components/schedule_detail.dart';
import 'package:projecti_fan_app/widget/components/streamer_detail.dart';
import 'package:projecti_fan_app/widget/group_select_widget.dart';
import 'package:projecti_fan_app/widget/help_page.dart';
import 'package:projecti_fan_app/widget/live_page.dart';
import 'package:projecti_fan_app/widget/screen_base_widget.dart';
import 'package:projecti_fan_app/widget/splash_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
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
      path: '/help',
      builder: (context, state) {
        return const HelpPage();
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
        // 프로필 데이터는 화면이 group/key로 캐시에서 읽는다 (extra 불필요).
        final group =
            Group.fromId(state.uri.queryParameters['group']) ?? Group.honeyz;
        final memberKey = state.uri.queryParameters['key'] ?? '';
        return StreamerDetail(
          group: group,
          memberKey: memberKey,
        );
      },
    ),
  ],
);

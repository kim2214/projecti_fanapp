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
        String url = state.uri.queryParameters['url']!;
        String name = state.uri.queryParameters['name']!;
        return ScheduleDetail(
          imageURL: url,
          name: name,
        );
      },
    ),
    GoRoute(
      path: '/streamerDetail',
      builder: (context, state) {
        final pjiMember = state.extra as StreamerModel;
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

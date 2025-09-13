import 'package:go_router/go_router.dart';
import 'package:honeyz_fan_app/model/streamer_model.dart';
import 'package:honeyz_fan_app/model/music_model.dart';
import 'package:honeyz_fan_app/widget/audio_widget.dart';
import 'package:honeyz_fan_app/widget/components/schedule_detail.dart';
import 'package:honeyz_fan_app/widget/components/streamer_detail.dart';
import 'package:honeyz_fan_app/widget/group_select_widget.dart';
import 'package:honeyz_fan_app/widget/screen_base_widget.dart';

import 'main.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return MyHomePage();
      },
    ),
    GoRoute(
      path: '/groupSelect',
      builder: (context, state) {
        return GroupSelectWidget();
      },
    ),
    GoRoute(
      path: '/baseScreen',
      builder: (context, state) {
        return ScreenBaseWidget();
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
        final honeyz = state.extra as StreamerModel;
        return StreamerDetail(honeyz: honeyz);
        // return StreamerDetail();
      },
    ),
    GoRoute(
      path: '/audioPage',
      builder: (context, state) {
        final musicModel = state.extra as MusicModel;
        return BackgroundAudioWidget(
          musicModel: musicModel,
        );
        // return StreamerDetail();
      },
    ),
  ],
);

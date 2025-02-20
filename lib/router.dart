import 'package:go_router/go_router.dart';
import 'package:honeyz_fan_app/model/honeyz_model.dart';
import 'package:honeyz_fan_app/widget/audio_widget.dart';
import 'package:honeyz_fan_app/widget/components/schedule_detail.dart';
import 'package:honeyz_fan_app/widget/components/streamer_detail.dart';

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
        final honeyz = state.extra as HoneyzModel;
        return StreamerDetail(honeyz: honeyz);
        // return StreamerDetail();
      },
    ),
    GoRoute(
      path: '/audioPage',
      builder: (context, state) {
        String musicURL = state.uri.queryParameters['musicURL']!;
        String thumbnail = state.uri.queryParameters['thumbnail']!;
        String title = state.uri.queryParameters['title']!;
        String name = state.uri.queryParameters['name']!;
        return AudioWidget(
          musicURL: musicURL,
          musicTitle: title,
          imgUrl: thumbnail,
          name: name,
        );
        // return StreamerDetail();
      },
    ),
  ],
);

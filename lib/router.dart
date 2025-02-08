import 'package:go_router/go_router.dart';
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
      path: '/detail',
      builder: (context, state) {
        return StreamerDetail();
      },
    ),
  ],
);

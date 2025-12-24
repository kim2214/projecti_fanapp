import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/favorite_controller.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/controllers/music_controller.dart';
import 'package:projecti_fan_app/controllers/youtube_controller.dart';

class BindingClass extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MusicController());
    Get.lazyPut(() => GlobalController());
    Get.put(FavoriteController()); // 앱 전체에서 사용되므로 put 사용
    Get.lazyPut(() => YouTubeController());
  }
}

// // Router에서 사용
// final router = GoRouter(
//   routes: [
//     GoRoute(
//       path: '/',
//       builder: (context, state) {
//         HomeBinding().dependencies();
//         return MyHomePage();
//       },
//     ),
//     GoRoute(
//       path: '/groupSelect',
//       builder: (context, state) {
//         GroupSelectBinding().dependencies();
//         return GroupSelectWidget();
//       },
//     ),
//     // 나머지 라우트들...
//   ],
// );

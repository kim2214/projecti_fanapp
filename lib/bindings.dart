import 'package:get/get.dart';
import 'package:honeyz_fan_app/controllers/global_controller.dart';
import 'package:honeyz_fan_app/controllers/music_controller.dart';

class BindingClass extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MusicController());
    Get.lazyPut(() => GlobalController());
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

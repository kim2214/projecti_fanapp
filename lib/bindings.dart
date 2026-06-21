import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/favorites_controller.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/controllers/youtube_controller.dart';

class BindingClass extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GlobalController());
    Get.lazyPut(() => YouTubeController());
    Get.lazyPut(() => FavoritesController());
  }
}

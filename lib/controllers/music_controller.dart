import 'package:get/get.dart';
import 'package:projecti_fan_app/model/music_model.dart';

class MusicController extends GetxController {
  RxList<MusicModel> originMusicList = <MusicModel>[].obs;
  RxList<MusicModel> musicList = <MusicModel>[].obs;

  RxInt musicIndex = 0.obs;
}

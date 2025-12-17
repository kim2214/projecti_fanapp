import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projecti_fan_app/model/music_model.dart';

class FavoriteController extends GetxController {
  static const String _favoritesKey = 'favorite_music_list';

  RxList<MusicModel> favoriteList = <MusicModel>[].obs;
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  /// SharedPreferences에서 즐겨찾기 목록 로드
  Future<void> loadFavorites() async {
    try {
      isLoading.value = true;
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_favoritesKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(jsonString);
        favoriteList.value =
            jsonList.map((e) => MusicModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// SharedPreferences에 즐겨찾기 목록 저장
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = favoriteList.map((e) => e.toJson()).toList();
      await prefs.setString(_favoritesKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  /// 즐겨찾기에 추가
  Future<void> addFavorite(MusicModel music) async {
    if (!isFavorite(music)) {
      favoriteList.add(music);
      await _saveFavorites();
    }
  }

  /// 즐겨찾기에서 제거
  Future<void> removeFavorite(MusicModel music) async {
    favoriteList.removeWhere((item) => item.musicURL == music.musicURL);
    await _saveFavorites();
  }

  /// 즐겨찾기 토글 (추가/제거)
  Future<void> toggleFavorite(MusicModel music) async {
    if (isFavorite(music)) {
      await removeFavorite(music);
    } else {
      await addFavorite(music);
    }
  }

  /// 해당 음악이 즐겨찾기에 있는지 확인
  bool isFavorite(MusicModel music) {
    return favoriteList.any((item) => item.musicURL == music.musicURL);
  }

  /// 즐겨찾기 전체 삭제
  Future<void> clearAllFavorites() async {
    favoriteList.clear();
    await _saveFavorites();
  }
}

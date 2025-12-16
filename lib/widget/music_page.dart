import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/controllers/music_controller.dart';
import 'package:projecti_fan_app/model/music_model.dart';
import 'package:projecti_fan_app/widget/components/music_card.dart';
import 'package:projecti_fan_app/widget/audio_common.dart';
import 'package:get/get.dart';

class MusicPageWidget extends StatefulWidget {
  const MusicPageWidget({super.key});

  @override
  State<MusicPageWidget> createState() => _MusicPageWidgetState();
}

class _MusicPageWidgetState extends State<MusicPageWidget>
    with AutomaticKeepAliveClientMixin {
  final musicController = Get.find<MusicController>();
  final globalController = Get.find<GlobalController>();

  final List<Map<String, String>> groupItems = [
    {'label': '전체', 'value': 'all', 'asset': 'assets/projecti_logo.png'},
    {'label': '허니즈', 'value': 'honeyz', 'asset': 'assets/honeyz_logo.png'},
    {'label': '아카시아', 'value': 'acaxia', 'asset': 'assets/acaxia_logo.png'},
  ];

  Future<List<MusicModel>> _loadFirestore() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    if (musicController.originMusicList.isEmpty) {
      QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection("music")
          .orderBy('created_at', descending: false)
          .get();
      musicController.originMusicList.value =
          snapshot.docs.map((e) => MusicModel.fromJson(e.data())).toList();
      musicController.musicList.value =
          snapshot.docs.map((e) => MusicModel.fromJson(e.data())).toList();
    }

    return musicController.musicList;
  }

  void _onGroupSelected(int index) {
    final selectedGroup = groupItems[index]['value']!;
    globalController.selectedMusicGroupString.value = selectedGroup;

    if (selectedGroup == 'all') {
      musicController.musicList.value = musicController.originMusicList;
    } else {
      musicController.musicList.value = musicController.originMusicList
          .where((music) => music.group!.contains(selectedGroup))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AudioTheme.backgroundLight,
            AudioTheme.backgroundMid,
            AudioTheme.background,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: FutureBuilder(
        future: _loadFirestore(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData == false) {
            return const Center(
              child: CircularProgressIndicator(
                color: AudioTheme.primary,
                strokeWidth: 3,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AudioTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '오류가 발생했습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: AudioTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Obx(() => _buildContent());
          }
        },
      ),
    );
  }

  Widget _buildContent() {
    final currentGroupIndex = groupItems.indexWhere(
      (item) => item['value'] == globalController.selectedMusicGroupString.value,
    );
    final currentGroup = groupItems[currentGroupIndex >= 0 ? currentGroupIndex : 0];

    return CustomScrollView(
      slivers: [
        // 헤더 영역
        SliverToBoxAdapter(
          child: _buildHeader(currentGroup),
        ),
        // 그룹 선택 칩
        SliverToBoxAdapter(
          child: _buildGroupSelector(currentGroupIndex >= 0 ? currentGroupIndex : 0),
        ),
        // 곡 수 및 정렬
        SliverToBoxAdapter(
          child: _buildSongCount(),
        ),
        // 음악 리스트
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MusicCard(
                    musicModel: musicController.musicList[index],
                    index: index,
                  ),
                );
              },
              childCount: musicController.musicList.length,
            ),
          ),
        ),
        // 하단 여백
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildHeader(Map<String, String> currentGroup) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      child: Row(
        children: [
          // 그룹 로고
          Hero(
            tag: 'group_logo',
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AudioTheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AudioTheme.primary.withAlpha(40),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  currentGroup['asset']!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // 그룹 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentGroup['label'] == '전체'
                      ? '프로젝트아이'
                      : currentGroup['label']!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AudioTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Music Collection',
                  style: TextStyle(
                    fontSize: 14,
                    color: AudioTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSelector(int selectedIndex) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: groupItems.length,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          final item = groupItems[index];

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => _onGroupSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AudioTheme.primary : AudioTheme.surface,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? AudioTheme.primary
                        : AudioTheme.primary.withAlpha(50),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AudioTheme.primary.withAlpha(60),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  item['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AudioTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSongCount() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AudioTheme.surfaceTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.music_note_rounded,
                      size: 16,
                      color: AudioTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${musicController.musicList.length}곡',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AudioTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 셔플 재생 버튼
          // Container(
          //   decoration: BoxDecoration(
          //     gradient: const LinearGradient(
          //       colors: [AudioTheme.primaryLight, AudioTheme.primary],
          //     ),
          //     borderRadius: BorderRadius.circular(20),
          //     boxShadow: [
          //       BoxShadow(
          //         color: AudioTheme.primary.withAlpha(60),
          //         blurRadius: 8,
          //         offset: const Offset(0, 3),
          //       ),
          //     ],
          //   ),
          //   child: Material(
          //     color: Colors.transparent,
          //     child: InkWell(
          //       borderRadius: BorderRadius.circular(20),
          //       onTap: () {
          //         // TODO: 셔플 재생 기능
          //       },
          //       child: const Padding(
          //         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          //         child: Row(
          //           children: [
          //             Icon(
          //               Icons.shuffle_rounded,
          //               size: 18,
          //               color: Colors.white,
          //             ),
          //             SizedBox(width: 6),
          //             Text(
          //               '셔플',
          //               style: TextStyle(
          //                 color: Colors.white,
          //                 fontWeight: FontWeight.w600,
          //                 fontSize: 13,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

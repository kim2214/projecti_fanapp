import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // 테마 컬러

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // 페이드 애니메이션 컨트롤러
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 스케일 애니메이션 컨트롤러
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 페이드 애니메이션
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // 스케일 애니메이션
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // 슬라이드 애니메이션
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // 애니메이션 시작
    _startAnimations();

    // 안전한 네비게이션을 위해 PostFrameCallback 사용
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateNext();
    });
  }

  void _startAnimations() {
    _fadeController.forward();
    _scaleController.forward();
  }

  Future<void> _navigateNext() async {
    // 저장된 그룹 복원과 최소 표시 시간(페이드 1.2초 + 여유)을 병행한다.
    // (예전엔 고정 2.5초 대기라 애니메이션이 끝나고도 1.3초를 낭비했다.)
    final results = await Future.wait([
      Get.find<GlobalController>().restoreSelectedGroup(),
      Future.delayed(const Duration(milliseconds: 1400)),
    ]);
    if (!mounted) return;

    final savedGroup = results.first as String?;
    if (savedGroup == null) {
      // 첫 실행(또는 저장값 없음/오류) — 기존처럼 그룹 선택으로.
      context.pushReplacement('/groupSelect');
      return;
    }

    // 스케줄은 진입을 막지 않고 미리 받아둔다 (그룹 선택 화면과 같은 정책 —
    // 실패하면 GlobalController가 안내 스낵바를 띄우고, 당겨서 새로고침도 있다).
    unawaited(Get.find<GlobalController>().loadScheduleFireStore());

    // 그룹 선택 화면을 스택 아래에 깔아 두어야 메인의 뒤로가기(pop)가 기존
    // 선택 흐름과 동일하게 그룹 선택으로 돌아간다 (pop 대상 없음 크래시 방지).
    context.pushReplacement('/groupSelect');
    context.push('/baseScreen');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.honeyz.withAlpha(40),
              context.bg,
              AppColors.acaxia.withAlpha(50),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              // 메인 로고 섹션
              _buildLogoSection(),
              const Spacer(flex: 2),
              // 로딩 인디케이터
              _buildLoadingIndicator(),
              const SizedBox(height: 40),
              // 하단 정보
              _buildFooter(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 로고 컨테이너
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.honeyz.withAlpha(40),
                    blurRadius: 30,
                    offset: const Offset(-10, 10),
                  ),
                  BoxShadow(
                    color: AppColors.acaxia.withAlpha(60),
                    blurRadius: 30,
                    offset: const Offset(10, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/fanapp_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // 그룹 뱃지들
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGroupBadge('HONEYZ', AppColors.honeyz),
              const SizedBox(width: 12),
              _buildGroupBadge('ACAXIA', AppColors.acaxia),
            ],
          ),
          const SizedBox(height: 24),
          // 앱 타이틀
          Text(
            '프로젝트아이',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: context.textMain,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 16,
                  color: AppColors.honeyz,
                ),
                const SizedBox(width: 8),
                Text(
                  '비공식 팬앱',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textSub,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupBadge(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withAlpha(200),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          SizedBox(
            width: 160,
            child: LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.honeyz),
              minHeight: 3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '로딩 중...',
            style: TextStyle(
              fontSize: 13,
              color: context.textFaint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Text(
            'PROJECT i FANAPP',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: context.textFaint,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Copyright © 2025 kimdev0821',
            style: TextStyle(
              fontSize: 11,
              color: context.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../quests/presentation/quests_screen.dart';
import '../../character/presentation/character_screen.dart';
import '../../pomodoro/presentation/pomodoro_screen.dart';
import '../../stats/presentation/stats_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../quests/providers/quest_provider.dart';
import '../../achievements/providers/achievement_provider.dart';
import '../../user/providers/user_provider.dart';
import '../../../core/widgets/level_up_overlay.dart';
import '../../user/data/user_model.dart';
import '../../onboarding/presentation/focus_questionnaire_overlay.dart';
import '../providers/shell_provider.dart';
import '../../../core/widgets/particle_background.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final List<Widget> _screens = const [
    DashboardScreen(),
    QuestsScreen(),
    PomodoroScreen(),
    StatsScreen(),
    CharacterScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    final currentIndex = ref.watch(shellIndexProvider);

    // Listen to currentUserProvider
    ref.listen<AsyncValue<UserModel?>>(currentUserProvider, (previous, next) {
      final u = next.value;
      if (u != null) {
        ref.read(questRepositoryProvider).ensureDailyQuests(u.uid);
        ref.read(questRepositoryProvider).ensureWeeklyQuests(u.uid);
        ref.read(achievementRepositoryProvider).initializeAchievements(u.uid);

        final oldUser = previous?.value;
        if (oldUser != null && u.level > oldUser.level) {
          LevelUpOverlay.show(context, newLevel: u.level, newTitle: u.title);
        }
      }
    });

    if (user != null && user.focusAreas.isEmpty) {
      return FocusQuestionnaireOverlay(uid: user.uid);
    }

    final dailyQuestsAsync = ref.watch(dailyQuestsProvider);
    final uncompletedCount = dailyQuestsAsync.maybeWhen(
      data: (quests) => quests.where((q) => !q.isCompleted).length,
      orElse: () => 0,
    );

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildAtmosphere()),
          const Positioned.fill(child: IgnorePointer(child: ParticleBackground())),
          ..._screens.asMap().entries.map((entry) {
            return Positioned.fill(
              child: _buildScreenLayer(entry.key, entry.value, currentIndex),
            );
          }),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(uncompletedCount, currentIndex),
    );
  }

  Widget _buildAtmosphere() {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.12),
                    AppColors.secondary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.10),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenLayer(int index, Widget screen, int currentIndex) {
    final isSelected = currentIndex == index;

    return IgnorePointer(
      ignoring: !isSelected,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        opacity: isSelected ? 1.0 : 0.0,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          offset: isSelected ? Offset.zero : const Offset(0.15, 0.0),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            scale: isSelected ? 1.0 : 0.92,
            child: screen,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(int badgeCount, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.dashboard_rounded, 'Ana Sayfa', currentIndex),
              _buildNavItem(1, Icons.assignment_rounded, 'Görevler', currentIndex, badgeCount: badgeCount),
              _buildNavItem(2, Icons.timer_rounded, 'Pomodoro', currentIndex),
              _buildNavItem(3, Icons.bar_chart_rounded, 'İstatistik', currentIndex),
              _buildNavItem(4, Icons.person_rounded, 'Karakter', currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, int currentIndex, {int badgeCount = 0}) {
    final isSelected = currentIndex == index;
    Widget iconWidget = Icon(
      icon,
      color: isSelected ? AppColors.primary : AppColors.textSecondary,
      size: 24,
    );

    if (badgeCount > 0) {
      iconWidget = Badge(
        label: Text(
          badgeCount.toString(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.error,
        child: iconWidget,
      );
    }

    return GestureDetector(
      onTap: () => ref.read(shellIndexProvider.notifier).setIndex(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

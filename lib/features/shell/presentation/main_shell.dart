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

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    QuestsScreen(),
    PomodoroScreen(),
    StatsScreen(),
    CharacterScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Listen to currentUserProvider
    ref.listen<AsyncValue<UserModel?>>(currentUserProvider, (previous, next) {
      final user = next.value;
      if (user != null) {
        ref.read(questRepositoryProvider).ensureDailyQuests(user.uid);
        ref.read(achievementRepositoryProvider).initializeAchievements(user.uid);

        final oldUser = previous?.value;
        if (oldUser != null && user.level > oldUser.level) {
          LevelUpOverlay.show(context, newLevel: user.level, newTitle: user.title);
        }
      }
    });

    final dailyQuestsAsync = ref.watch(dailyQuestsProvider);
    final uncompletedCount = dailyQuestsAsync.maybeWhen(
      data: (quests) => quests.where((q) => !q.isCompleted).length,
      orElse: () => 0,
    );

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(uncompletedCount),
    );
  }

  Widget _buildBottomNav(int badgeCount) {
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
              _buildNavItem(0, Icons.dashboard_rounded, 'Ana Sayfa'),
              _buildNavItem(1, Icons.assignment_rounded, 'Görevler', badgeCount: badgeCount),
              _buildNavItem(2, Icons.timer_rounded, 'Pomodoro'),
              _buildNavItem(3, Icons.bar_chart_rounded, 'İstatistik'),
              _buildNavItem(4, Icons.person_rounded, 'Karakter'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {int badgeCount = 0}) {
    final isSelected = _currentIndex == index;
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
      onTap: () => setState(() => _currentIndex = index),
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

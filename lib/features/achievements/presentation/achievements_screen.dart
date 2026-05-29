import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../data/achievement_model.dart';
import '../providers/achievement_provider.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievementsAsync = ref.watch(userAchievementsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Başarımlar',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textSecondary,
          isScrollable: true,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.normal, fontSize: 13),
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'Streak'),
            Tab(text: 'Pomodoro'),
            Tab(text: 'Görev'),
            Tab(text: 'Level'),
          ],
        ),
      ),
      body: achievementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(
          child: Text(
            'Başarımlar yüklenirken hata oluştu',
            style: GoogleFonts.inter(color: AppColors.error),
          ),
        ),
        data: (list) {
          final streakList = list.where((a) => a.category == 'streak').toList();
          final pomodoroList = list.where((a) => a.category == 'pomodoro').toList();
          final questList = list.where((a) => a.category == 'quest').toList();
          final levelList = list.where((a) => a.category == 'level' || a.category == 'stat').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAchievementList(list),
              _buildAchievementList(streakList),
              _buildAchievementList(pomodoroList),
              _buildAchievementList(questList),
              _buildAchievementList(levelList),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAchievementList(List<AchievementModel> achievements) {
    if (achievements.isEmpty) {
      return Center(
        child: Text(
          'Bu kategoride başarım bulunmuyor.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (ctx, i) {
        final achievement = achievements[i];
        return _buildAchievementCard(context, achievement);
      },
    );
  }

  Widget _buildAchievementCard(BuildContext context, AchievementModel achievement) {
    final double progress = achievement.requiredValue > 0
        ? (achievement.currentValue / achievement.requiredValue).clamp(0.0, 1.0)
        : 0.0;

    if (achievement.isUnlocked) {
      // Unlocked achievement card: Golden glow border, gold badge emoji icon, unlocked lock, and unlocked date
      return GestureDetector(
        onTap: () => _showAchievementDetail(context, achievement),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              // Badge icon container with gold glow
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.gold, Color(0xFFFFA000)],
                  ),
                  boxShadow: [
                    BoxShadow(color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 8),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 14),
              // Title/Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (achievement.unlockedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Kazanıldı: ${DateFormat('dd.MM.yyyy').format(achievement.unlockedAt!)}',
                        style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Unlocked icon
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_open_rounded, color: AppColors.gold, size: 22),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${achievement.xpReward} XP',
                      style: GoogleFonts.inter(
                        color: AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      // Locked achievement card: Greyed out, showing silhouette icon, locked lock symbol, progress bar
      return GestureDetector(
        onTap: () => _showAchievementDetail(context, achievement),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceLight, width: 1),
          ),
          child: Row(
            children: [
              // Silhouette icon
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceLight,
                ),
                alignment: Alignment.center,
                child: const Text(
                  '❓',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 14),
              // Title/Description/Progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.background,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'İlerleme: ${achievement.currentValue}/${achievement.requiredValue}',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Locked lock icon
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_rounded, color: AppColors.textSecondary.withValues(alpha: 0.4), size: 22),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${achievement.xpReward} XP',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showAchievementDetail(BuildContext context, AchievementModel achievement) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: achievement.isUnlocked ? AppColors.gold : AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            Text(
              achievement.isUnlocked ? achievement.icon : '🔒',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                achievement.title,
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement.description,
              style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.75), fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              achievement.isUnlocked
                  ? 'Kilidi Açıldı! 🎉'
                  : 'Durum: Kilitli',
              style: GoogleFonts.inter(
                color: achievement.isUnlocked ? AppColors.gold : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ödül: ${achievement.xpReward} XP',
              style: GoogleFonts.inter(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              'İlerleme: ${achievement.currentValue} / ${achievement.requiredValue}',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              'Kapat',
              style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }
}

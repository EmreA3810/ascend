import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_stat_bar.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../user/providers/user_provider.dart';
import '../../user/data/user_model.dart';
import '../../achievements/providers/achievement_provider.dart';
import '../../achievements/data/achievement_model.dart';
import '../../quests/providers/quest_provider.dart';
import '../../quests/data/quest_model.dart';
import '../../pomodoro/providers/pomodoro_provider.dart';

class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  String _formatElapsedTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.isNegative) return 'Şimdi';
    if (diff.inSeconds < 60) return 'Şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    return DateFormat('dd.MM.yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final achievementsAsync = ref.watch(userAchievementsProvider);
    final dailyQuestsAsync = ref.watch(dailyQuestsProvider);
    final todaySessionsAsync = ref.watch(todaySessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Karakter Profil',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Hata: $err', style: GoogleFonts.inter(color: AppColors.error))),
        data: (user) {
          if (user == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          // Fetch achievements
          final achievements = achievementsAsync.value ?? [];
          final unlockedAchievements = achievements.where((a) => a.isUnlocked).toList();

          // Merge activities
          final completedQuests = dailyQuestsAsync.value?.where((q) => q.isCompleted).toList() ?? [];
          final completedSessions = todaySessionsAsync.value ?? [];

          final List<Map<String, dynamic>> activities = [];
          
          for (final q in completedQuests) {
            activities.add({
              'title': '${q.title} Tamamlandı',
              'time': q.completedAt ?? q.createdAt,
              'icon': QuestModel.iconFromName(q.iconName),
              'color': AppColors.success,
            });
          }

          for (final s in completedSessions) {
            activities.add({
              'title': '${s.workMinutes} dk Pomodoro',
              'time': s.endedAt,
              'icon': Icons.timer_rounded,
              'color': AppColors.secondary,
            });
          }

          activities.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCharacterHero(user),
                const SizedBox(height: 20),
                _buildStatsSection(user),
                const SizedBox(height: 20),
                _buildAchievementsSection(unlockedAchievements),
                const SizedBox(height: 20),
                _buildTimelineSection(activities),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCharacterHero(UserModel user) {
    final xpRatio = user.xpToNextLevel > 0 ? (user.xp / user.xpToNextLevel).clamp(0.0, 1.0) : 0.0;

    return GlassmorphicCard(
      borderColor: AppColors.primary,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar with glow
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: 3)],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            user.displayName,
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
            ),
            child: Text(
              '⚔️ Level ${user.level} — ${user.title}',
              style: GoogleFonts.inter(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
          // XP Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Deneyim (XP)', style: GoogleFonts.inter(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('${user.xp} / ${user.xpToNextLevel}', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(height: 10, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(5))),
                  FractionallySizedBox(
                    widthFactor: xpRatio,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.success, AppColors.secondary]),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1)],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('Özellikler', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              AnimatedStatBar(
                label: 'Odak (Focus)',
                value: user.stats['focus'] ?? 0,
                maxValue: 100,
                color: AppColors.statFocus,
              ),
              const SizedBox(height: 14),
              AnimatedStatBar(
                label: 'Enerji (Energy)',
                value: user.stats['energy'] ?? 0,
                maxValue: 100,
                color: AppColors.statEnergy,
              ),
              const SizedBox(height: 14),
              AnimatedStatBar(
                label: 'Bilgi (Knowledge)',
                value: user.stats['knowledge'] ?? 0,
                maxValue: 100,
                color: AppColors.statKnowledge,
              ),
              const SizedBox(height: 14),
              AnimatedStatBar(
                label: 'Güç (Strength)',
                value: user.stats['strength'] ?? 0,
                maxValue: 100,
                color: AppColors.statStrength,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(List<AchievementModel> unlockedAchievements) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 20),
            const SizedBox(width: 8),
            Text('Açılan Başarımlar (${unlockedAchievements.length})', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 12),
        unlockedAchievements.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Henüz açılmış başarım bulunmuyor. 🔒',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: unlockedAchievements.length,
                itemBuilder: (ctx, i) {
                  final a = unlockedAchievements[i];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(color: AppColors.gold.withValues(alpha: 0.05), blurRadius: 8),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(a.icon, style: const TextStyle(fontSize: 22)),
                            const Icon(Icons.lock_open_rounded, color: AppColors.gold, size: 16),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          a.title,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          a.description,
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildTimelineSection(List<Map<String, dynamic>> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timeline_rounded, color: AppColors.secondary, size: 20),
            const SizedBox(width: 8),
            Text('Aktivite Geçmişi', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 12),
        activities.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Henüz aktivite geçmişi yok.',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activities.length.clamp(0, 10), // Limit to 10
                  itemBuilder: (ctx, i) {
                    final act = activities[i];
                    final title = act['title'] as String;
                    final time = _formatElapsedTime(act['time'] as DateTime);
                    final icon = act['icon'] as IconData;
                    final color = act['color'] as Color;
                    final isLast = i == activities.length - 1 || i == 9;

                    return IntrinsicHeight(
                      child: Row(
                        children: [
                          // Timeline indicator
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: color, width: 1.5),
                                ),
                                child: Icon(icon, color: color, size: 14),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          // Content details
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    time,
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }
}

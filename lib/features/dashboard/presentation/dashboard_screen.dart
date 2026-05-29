import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../../core/widgets/animated_stat_bar.dart';
import '../../../core/widgets/xp_gain_popup.dart';
import '../../user/providers/user_provider.dart';
import '../../user/data/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../quests/providers/quest_provider.dart';
import '../../quests/data/quest_model.dart';
import '../../pomodoro/providers/pomodoro_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _xpAnimController;
  late Animation<double> _xpAnimation;
  double _previousXpRatio = 0;

  @override
  void initState() {
    super.initState();
    _xpAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _xpAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _xpAnimController, curve: Curves.easeOutCubic),
    );
  }

  void _animateXp(double target) {
    _xpAnimation = Tween<double>(begin: _previousXpRatio, end: target).animate(
      CurvedAnimation(parent: _xpAnimController, curve: Curves.easeOutCubic),
    );
    _xpAnimController
      ..reset()
      ..forward();
    _previousXpRatio = target;
  }

  @override
  void dispose() {
    _xpAnimController.dispose();
    super.dispose();
  }

  String _formatElapsedTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.isNegative) return 'Şimdi';
    if (diff.inSeconds < 60) return 'Şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    return DateFormat('dd.MM.yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Hata: $e', style: GoogleFonts.inter(color: AppColors.error))),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final xpRatio = user.xpToNextLevel > 0
            ? user.xp / user.xpToNextLevel
            : 0.0;
        if (_previousXpRatio != xpRatio) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _animateXp(xpRatio));
        }

        return _buildBody(context, user);
      },
    );
  }

  Widget _buildBody(BuildContext context, UserModel user) {
    final dailyQuestsAsync = ref.watch(dailyQuestsProvider);
    final todaySessionsAsync = ref.watch(todaySessionsProvider);

    // Merge activities
    final completedQuests = dailyQuestsAsync.value?.where((q) => q.isCompleted).toList() ?? [];
    final completedSessions = todaySessionsAsync.value ?? [];

    final List<Map<String, dynamic>> activities = [];
    
    for (final q in completedQuests) {
      activities.add({
        'title': '${q.title} Tamamlandı',
        'time': q.completedAt ?? q.createdAt,
        'xp': '+${q.xpReward} XP',
        'icon': QuestModel.iconFromName(q.iconName),
        'color': AppColors.success,
      });
    }

    for (final s in completedSessions) {
      activities.add({
        'title': '${s.workMinutes} dk Pomodoro',
        'time': s.endedAt,
        'xp': '+${s.xpEarned} XP',
        'icon': Icons.timer_rounded,
        'color': AppColors.secondary,
      });
    }

    // Sort by time descending
    activities.sort((a, b) {
      final tA = a['time'] as DateTime;
      final tB = b['time'] as DateTime;
      return tB.compareTo(tA);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(user),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeroCard(user),
                const SizedBox(height: 20),
                
                // Character Stats Panel (Using GlassmorphicCard and AnimatedStatBars)
                _buildStatsPanel(user),
                const SizedBox(height: 20),
                
                // Daily Quests Panel
                _buildSectionTitle('Günlük Görevler', Icons.local_fire_department),
                const SizedBox(height: 12),
                _buildDailyQuestsPanel(user.uid, dailyQuestsAsync),
                const SizedBox(height: 20),
                
                // Activities Panel
                _buildSectionTitle('Son Aktiviteler', Icons.history),
                const SizedBox(height: 12),
                _buildActivityFeed(activities),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(UserModel user) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: AppColors.background,
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ).createShader(bounds),
        child: Text(
          'ASCEND',
          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
              const SizedBox(width: 4),
              Text('${user.streak} Gün', style: GoogleFonts.inter(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: const CircleAvatar(radius: 18, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white, size: 20)),
          color: AppColors.cardBackground,
          onSelected: (val) async {
            if (val == 'signout') {
              await ref.read(authRepositoryProvider).signOut();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'signout', child: Row(
              children: [
                const Icon(Icons.logout, color: Colors.white70, size: 18), 
                const SizedBox(width: 8), 
                Text('Çıkış Yap', style: GoogleFonts.inter(color: Colors.white))
              ],
            )),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeroCard(UserModel user) {
    return GlassmorphicCard(
      borderColor: AppColors.primary,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 2)],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                      ),
                      child: Text('LVL ${user.level} · ${user.title}',
                          style: GoogleFonts.inter(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(height: 6),
                    Text(user.displayName,
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('XP', style: GoogleFonts.inter(
                color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13,
                shadows: [Shadow(color: AppColors.success.withValues(alpha: 0.8), blurRadius: 6)],
              )),
              Text('${user.xp} / ${user.xpToNextLevel}',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _xpAnimation,
            builder: (context, _) {
              return Stack(
                children: [
                  Container(height: 10, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(5))),
                  FractionallySizedBox(
                    widthFactor: _xpAnimation.value.clamp(0.0, 1.0),
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
              );
            },
          ),
          const SizedBox(height: 6),
          Text('${user.xpToNextLevel - user.xp} XP kaldı → Level ${user.level + 1}',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStatsPanel(UserModel user) {
    return GlassmorphicCard(
      borderColor: AppColors.secondary,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Karakter Statları',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedStatBar(
            label: 'Odak (Focus)',
            value: user.stats['focus'] ?? 0,
            maxValue: 100,
            color: AppColors.statFocus,
          ),
          const SizedBox(height: 12),
          AnimatedStatBar(
            label: 'Enerji (Energy)',
            value: user.stats['energy'] ?? 0,
            maxValue: 100,
            color: AppColors.statEnergy,
          ),
          const SizedBox(height: 12),
          AnimatedStatBar(
            label: 'Bilgi (Knowledge)',
            value: user.stats['knowledge'] ?? 0,
            maxValue: 100,
            color: AppColors.statKnowledge,
          ),
          const SizedBox(height: 12),
          AnimatedStatBar(
            label: 'Güç (Strength)',
            value: user.stats['strength'] ?? 0,
            maxValue: 100,
            color: AppColors.statStrength,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildDailyQuestsPanel(String uid, AsyncValue<List<QuestModel>> dailyQuestsAsync) {
    return dailyQuestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, stack) => Center(
        child: Text('Görevler yüklenirken hata oluştu', style: GoogleFonts.inter(color: AppColors.error)),
      ),
      data: (quests) {
        if (quests.isEmpty) {
          return GlassmorphicCard(
            borderColor: AppColors.primary,
            child: Column(
              children: [
                Text(
                  'Bugün için görev bulunmuyor!',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ref.read(questRepositoryProvider).ensureDailyQuests(uid);
                  },
                  child: Text('Günlük Görevleri Oluştur', style: GoogleFonts.inter(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        return Column(
          children: quests.map((q) => _buildQuestCard(uid, q)).toList(),
        );
      },
    );
  }

  Widget _buildQuestCard(String uid, QuestModel quest) {
    final isDone = quest.isCompleted;
    final iconData = QuestModel.iconFromName(quest.iconName);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? AppColors.success.withValues(alpha: 0.4) : AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDone ? AppColors.success : AppColors.primary).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, color: isDone ? AppColors.success : AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: GoogleFonts.inter(
                    color: isDone ? AppColors.textSecondary : Colors.white,
                    fontWeight: FontWeight.bold,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text('+${quest.xpReward} XP', style: GoogleFonts.inter(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final nextCompleted = !quest.isCompleted;
              await ref.read(questRepositoryProvider).toggleQuest(uid, quest.id, nextCompleted);
              
              if (nextCompleted && mounted) {
                XpGainPopup.show(
                  context,
                  xp: quest.xpReward,
                  statName: quest.statBoost,
                  statAmount: 1,
                );
              }
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isDone
                  ? const Icon(Icons.check_circle, color: AppColors.success, size: 26, key: ValueKey(true))
                  : const Icon(Icons.radio_button_unchecked, color: AppColors.textSecondary, size: 26, key: ValueKey(false)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed(List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) {
      return GlassmorphicCard(
        borderColor: AppColors.textSecondary.withValues(alpha: 0.2),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Bugün henüz bir aktivite yok. 🎯',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ),
      );
    }

    // Limit to 5 activities
    final displayedActivities = activities.take(5).toList();

    return Column(
      children: displayedActivities.map((act) {
        return _buildActivityCard(act);
      }).toList(),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> act) {
    final title = act['title'] as String;
    final timeStr = _formatElapsedTime(act['time'] as DateTime);
    final xp = act['xp'] as String;
    final icon = act['icon'] as IconData;
    final color = act['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(timeStr, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(xp, style: GoogleFonts.inter(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

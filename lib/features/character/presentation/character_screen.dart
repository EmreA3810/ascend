import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../user/providers/user_provider.dart';
import '../../user/data/user_model.dart';
import '../../achievements/providers/achievement_provider.dart';
import '../../achievements/data/achievement_model.dart';
import '../../quests/providers/quest_provider.dart';
import '../../quests/data/quest_model.dart';
import '../../pomodoro/providers/pomodoro_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../stats/presentation/stats_screen.dart';
import 'character_painter.dart';
import 'wardrobe_screen.dart';

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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(
            'Karakter & Gelişim',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white54,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.shield_outlined, size: 18), text: 'Karakter & Gardırop'),
              Tab(icon: Icon(Icons.bar_chart_rounded, size: 18), text: 'İstatistik & Grafikler'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            userAsync.when(
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
                _revealSection(order: 0, child: _buildCharacterHero(context, ref, user)),
                const SizedBox(height: 20),
                _revealSection(order: 1, child: _buildStatsSection(user)),
                const SizedBox(height: 20),
                _revealSection(order: 2, child: _buildAchievementsSection(unlockedAchievements)),
                const SizedBox(height: 20),
                _revealSection(order: 3, child: _buildTimelineSection(activities)),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
      const StatsScreen(showAppBar: false),
    ],
  ),
),
);
  }

  Widget _revealSection({required Widget child, required int order}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (order * 140)),
      curve: Curves.easeOutBack,
      builder: (context, value, sectionChild) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 32 * (1 - value)),
            child: Transform.scale(
              scale: 0.82 + (0.18 * value),
              child: sectionChild,
            ),
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildCharacterHero(BuildContext context, WidgetRef ref, UserModel user) {
    final xpRatio = user.xpToNextLevel > 0 ? (user.xp / user.xpToNextLevel).clamp(0.0, 1.0) : 0.0;

    return GlassmorphicCard(
      borderColor: AppColors.primary,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // RPG Level Badge
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'LV',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    '${user.level}',
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Character Name
          Text(
            user.displayName,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          // Character Title/Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Legendary Ascender',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 14),
            ],
          ),
          const SizedBox(height: 20),
          // Live Character Avatar with tap to open wardrobe
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WardrobeScreen()),
              );
            },
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardBackground,
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.25),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: CharacterAvatar(
                equippedItems: user.equippedItems,
                size: 80,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.checkroom_rounded, color: AppColors.secondary, size: 13),
              const SizedBox(width: 4),
              Text(
                'Giydir / Gardırop',
                style: GoogleFonts.inter(
                  color: AppColors.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_rounded, color: AppColors.secondary, size: 12),
                const SizedBox(width: 6),
                Text(
                  'Level ${user.level} — ${user.title}',
                  style: GoogleFonts.inter(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildFocusAreasRow(context, ref, user),
          const SizedBox(height: 16),
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

  Widget _buildFocusAreasRow(BuildContext context, WidgetRef ref, UserModel user) {
    final areas = user.focusAreas.where((a) => a != 'skipped').toList();
    
    String getLabel(String id) {
      switch (id) {
        case 'academic': return 'Ders';
        case 'fitness': return 'Spor';
        case 'reading': return 'Okuma';
        case 'coding': return 'Kod';
        default: return id;
      }
    }

    IconData getIcon(String id) {
      switch (id) {
        case 'academic': return Icons.school_rounded;
        case 'fitness': return Icons.fitness_center_rounded;
        case 'reading': return Icons.menu_book_rounded;
        case 'coding': return Icons.code_rounded;
        default: return Icons.star_rounded;
      }
    }

    Color getColor(String id) {
      switch (id) {
        case 'academic': return AppColors.statKnowledge;
        case 'fitness': return AppColors.statStrength;
        case 'reading': return AppColors.primary;
        case 'coding': return AppColors.statFocus;
        default: return AppColors.textSecondary;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              if (areas.isEmpty)
                Text(
                  'Odak alanı seçilmedi',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
                )
              else
                ...areas.map((id) {
                  final color = getColor(id);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(getIcon(id), color: color, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          getLabel(id),
                          style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.settings_suggest_rounded, color: AppColors.secondary, size: 20),
          onPressed: () => _showEditFocusAreasSheet(context, ref, user),
        ),
      ],
    );
  }

  void _showEditFocusAreasSheet(BuildContext context, WidgetRef ref, UserModel user) {
    final List<String> currentSelected = List.from(user.focusAreas.where((a) => a != 'skipped'));
    
    final List<Map<String, dynamic>> options = [
      {'id': 'academic', 'label': 'Ders Çalışma & Akademi', 'icon': Icons.school_rounded, 'color': AppColors.statKnowledge},
      {'id': 'fitness', 'label': 'Spor & Sağlıklı Yaşam', 'icon': Icons.fitness_center_rounded, 'color': AppColors.statStrength},
      {'id': 'reading', 'label': 'Kişisel Gelişim & Okuma', 'icon': Icons.menu_book_rounded, 'color': AppColors.primary},
      {'id': 'coding', 'label': 'Yazılım & Kariyer / İş', 'icon': Icons.code_rounded, 'color': AppColors.statFocus},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'ODAK ALANLARINI DÜZENLE',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seçtiğiniz odak alanlarına göre günlük ve haftalık görevleriniz yarından itibaren güncellenecektir.',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  ...options.map((opt) {
                    final id = opt['id'] as String;
                    final isSelected = currentSelected.contains(id);
                    final color = opt['color'] as Color;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              currentSelected.remove(id);
                            } else {
                              currentSelected.add(id);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withValues(alpha: 0.1) : AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : AppColors.primary.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(opt['icon'] as IconData, color: color, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  opt['label'] as String,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Icon(
                                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: isSelected ? color : AppColors.textSecondary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'İptal',
                            style: GoogleFonts.inter(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          onPressed: () async {
                            final finalAreas = currentSelected.isEmpty ? ['skipped'] : currentSelected;
                            await ref.read(userRepositoryProvider).updateFocusAreas(user.uid, finalAreas);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Odak alanları güncellendi! Yarından itibaren geçerli olacak. 🚀'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          },
                          child: Text(
                            'Kaydet',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsSection(UserModel user) {
    final str = (user.stats['strength'] ?? 0).toDouble();
    final energy = (user.stats['energy'] ?? 0).toDouble();
    final focus = (user.stats['focus'] ?? 0).toDouble();
    final knowledge = (user.stats['knowledge'] ?? 0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.secondary, size: 20),
                const SizedBox(width: 8),
                Text('Karakter Nitelikleri', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            if (user.statPoints > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.gold, Colors.deepOrangeAccent]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 6),
                  ],
                ),
                child: Text(
                  '⚡ ${user.statPoints} Boş Puan',
                  style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              // Radar Chart (4 Core Attributes)
              SizedBox(
                height: 180,
                child: RadarChart(
                  RadarChartData(
                    dataSets: [
                      RadarDataSet(
                        fillColor: AppColors.secondary.withValues(alpha: 0.2),
                        borderColor: AppColors.secondary,
                        entryRadius: 3,
                        dataEntries: [
                          RadarEntry(value: str),
                          RadarEntry(value: energy),
                          RadarEntry(value: focus),
                          RadarEntry(value: knowledge),
                        ],
                      ),
                    ],
                    radarShape: RadarShape.polygon,
                    titlePositionPercentageOffset: 0.2,
                    getTitle: (index, angle) {
                      switch (index) {
                        case 0: return const RadarChartTitle(text: 'STR');
                        case 1: return const RadarChartTitle(text: 'ENG');
                        case 2: return const RadarChartTitle(text: 'FOC');
                        case 3: return const RadarChartTitle(text: 'KNW');
                        default: return const RadarChartTitle(text: '');
                      }
                    },
                    tickCount: 3,
                    ticksTextStyle: const TextStyle(color: Colors.white24, fontSize: 8),
                    gridBorderData: const BorderSide(color: Colors.white10),
                    tickBorderData: const BorderSide(color: Colors.white10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Grid details (4 Core RPG Stats)
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 0.95,
                mainAxisSpacing: 12,
                crossAxisSpacing: 8,
                children: [
                  _buildRPGStatCard('STR', user.stats['strength'] ?? 0, AppColors.statStrength, 'Güç'),
                  _buildRPGStatCard('ENG', user.stats['energy'] ?? 0, AppColors.statEnergy, 'Enerji'),
                  _buildRPGStatCard('FOC', user.stats['focus'] ?? 0, AppColors.statFocus, 'Odak'),
                  _buildRPGStatCard('KNW', user.stats['knowledge'] ?? 0, AppColors.statKnowledge, 'Bilgi'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRPGStatCard(String name, int value, Color color, [String? label]) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$value',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        if (label != null)
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white54,
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
                    'Henüz açılmış başarım bulunmuyor.',
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
                            Icon(_getAchievementIcon(a.category), color: AppColors.gold, size: 22),
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

  IconData _getAchievementIcon(String category) {
    switch (category) {
      case 'streak': return Icons.local_fire_department_rounded;
      case 'pomodoro': return Icons.timer_rounded;
      case 'quest': return Icons.assignment_turned_in_rounded;
      case 'level': return Icons.trending_up_rounded;
      case 'stat': return Icons.insights_rounded;
      default: return Icons.emoji_events_rounded;
    }
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

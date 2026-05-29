import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../user/data/user_model.dart';
import '../../user/providers/user_provider.dart';
import '../../pomodoro/providers/pomodoro_provider.dart';
import '../../pomodoro/data/pomodoro_session_model.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final weekSessionsAsync = ref.watch(weekSessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'İstatistikler',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Hata: $e', style: GoogleFonts.inter(color: AppColors.error))),
        data: (user) {
          if (user == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(user),
                const SizedBox(height: 20),
                
                // Chart Panel
                _buildSectionTitle('Haftalık Odak Grafiği', Icons.bar_chart_rounded),
                const SizedBox(height: 12),
                _buildChartPanel(weekSessionsAsync),
                const SizedBox(height: 24),
                
                // Weekly history list
                _buildSectionTitle('Bu Haftanın Odak Seansları', Icons.history),
                const SizedBox(height: 12),
                _buildWeeklyHistoryList(weekSessionsAsync),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(UserModel user) {
    final xpRemaining = (user.xpToNextLevel - user.xp).clamp(0, user.xpToNextLevel);
    final xpRatio = user.xpToNextLevel > 0 ? user.xp / user.xpToNextLevel : 0.0;

    return GlassmorphicCard(
      borderColor: AppColors.primary,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.displayName,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.title,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildHeroChip('Seviye ${user.level}', Icons.auto_awesome),
              const SizedBox(width: 10),
              _buildHeroChip(
                '${user.streak} Gün Seri',
                Icons.local_fire_department,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: xpRatio.clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.success, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sonraki seviyeye $xpRemaining XP kaldı',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPanel(AsyncValue<List<PomodoroSessionModel>> weekSessionsAsync) {
    return weekSessionsAsync.when(
      loading: () => Container(
        height: 250,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Container(
        height: 250,
        alignment: Alignment.center,
        child: Text('Grafik yüklenemedi: $e', style: GoogleFonts.inter(color: AppColors.error)),
      ),
      data: (sessions) {
        // Prepare weekday data: index 0 (Mon) to 6 (Sun)
        final List<double> workMinutesPerDay = List.filled(7, 0.0);
        final List<double> breakMinutesPerDay = List.filled(7, 0.0);

        for (final s in sessions) {
          final weekday = s.startedAt.weekday; // 1 (Mon) to 7 (Sun)
          workMinutesPerDay[weekday - 1] += s.workMinutes.toDouble();
          breakMinutesPerDay[weekday - 1] += s.breakMinutes.toDouble();
        }

        // Determine max Y for scale
        double maxVal = 30.0; // minimum scale size
        for (int i = 0; i < 7; i++) {
          if (workMinutesPerDay[i] > maxVal) maxVal = workMinutesPerDay[i];
          if (breakMinutesPerDay[i] > maxVal) maxVal = breakMinutesPerDay[i];
        }
        maxVal = (maxVal / 10).ceil() * 10.0 + 10.0; // round up to multiple of 10

        return GlassmorphicCard(
          borderColor: AppColors.secondary.withValues(alpha: 0.4),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Çalışma (dk)', AppColors.secondary),
                  const SizedBox(width: 20),
                  _buildLegendItem('Mola (dk)', AppColors.primary),
                ],
              ),
              const SizedBox(height: 24),
              // Chart
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxVal,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.cardBackground,
                        tooltipBorder: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final typeName = rodIndex == 0 ? 'Çalışma' : 'Mola';
                          return BarTooltipItem(
                            '$typeName\n${rod.toY.round()} dk',
                            GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                            final idx = value.toInt();
                            if (idx >= 0 && idx < 7) {
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(days[idx], style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}', style: GoogleFonts.inter(color: Colors.white70, fontSize: 10));
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (val) => FlLine(
                        color: AppColors.surfaceLight.withValues(alpha: 0.5),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(7, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: workMinutesPerDay[i],
                            color: AppColors.secondary,
                            width: 6,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          BarChartRodData(
                            toY: breakMinutesPerDay[i],
                            color: AppColors.primary,
                            width: 6,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildWeeklyHistoryList(AsyncValue<List<PomodoroSessionModel>> weekSessionsAsync) {
    return weekSessionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Yüklenemedi: $e')),
      data: (sessions) {
        if (sessions.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.auto_graph_rounded, color: AppColors.textSecondary, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Bu hafta henüz odak seansı yok.',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sessions.length,
          itemBuilder: (ctx, i) {
            final session = sessions[i];
            final formattedDate = DateFormat('dd.MM.yyyy, HH:mm').format(session.startedAt);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.timer_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${session.workMinutes} Dakika Odaklanma',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedDate,
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '+${session.xpEarned} XP',
                    style: GoogleFonts.inter(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

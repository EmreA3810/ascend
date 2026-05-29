import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../data/pomodoro_session_model.dart';
import '../providers/pomodoro_provider.dart';

class SessionHistorySheet extends ConsumerWidget {
  const SessionHistorySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSessionsAsync = ref.watch(allSessionsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FOKUS GEÇMİŞİ',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(color: AppColors.primary.withValues(alpha: 0.8), blurRadius: 10),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          allSessionsAsync.when(
            loading: () => const Expanded(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (err, stack) => Expanded(
              child: Center(
                child: Text('Veriler yüklenirken hata oluştu: $err', style: const TextStyle(color: AppColors.error)),
              ),
            ),
            data: (sessions) {
              // Summaries
              final totalSessions = sessions.length;
              final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.workMinutes);
              final totalXp = sessions.fold<int>(0, (sum, s) => sum + s.xpEarned);
              final totalHours = (totalMinutes / 60).toStringAsFixed(1);

              return Expanded(
                child: Column(
                  children: [
                    // Summary panels
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Toplam Seans',
                            totalSessions.toString(),
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryCard(
                            'Odaklanma',
                            '$totalHours Saat',
                            AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryCard(
                            'Toplam XP',
                            '+$totalXp',
                            AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Sessions List
                    Expanded(
                      child: sessions.isEmpty
                          ? Center(
                              child: Text(
                                'Henüz tamamlanmış bir odaklanma seansı bulunamadı.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(color: AppColors.textSecondary),
                              ),
                            )
                          : ListView.builder(
                              itemCount: sessions.length,
                              itemBuilder: (ctx, i) {
                                final session = sessions[i];
                                return _buildSessionTile(session);
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              shadows: [
                Shadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(PomodoroSessionModel session) {
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
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${session.workMinutes} Dakika Odaklanma',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${session.xpEarned} XP',
                style: GoogleFonts.inter(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              if (session.breakMinutes > 0)
                Text(
                  '${session.breakMinutes} dk mola',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

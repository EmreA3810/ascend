import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Karakter', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCharacterHero(context),
            const SizedBox(height: 20),
            _buildStatsSection(context),
            const SizedBox(height: 20),
            _buildAchievementsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.3),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 24),
        ],
      ),
      child: Column(
        children: [
          // Avatar with glow
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: 4)],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 16),
          const Text('Emre', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
            ),
            child: const Text(
              '⚔️ Level 7 — Disiplinli Savaşçı',
              style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          // XP Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('XP', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                  Text('3200 / 5000', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(height: 10, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(5))),
                  FractionallySizedBox(
                    widthFactor: 0.64,
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

  Widget _buildStatsSection(BuildContext context) {
    final stats = [
      {'label': '🧠 Odak', 'value': 18, 'max': 50, 'color': AppColors.secondary},
      {'label': '⚡ Enerji', 'value': 24, 'max': 50, 'color': AppColors.primary},
      {'label': '📚 Bilgi', 'value': 31, 'max': 50, 'color': Colors.orangeAccent},
      {'label': '💪 Güç', 'value': 15, 'max': 50, 'color': Colors.pinkAccent},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Özellikler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: stats.map((s) {
              final val = s['value'] as int;
              final max = s['max'] as int;
              final color = s['color'] as Color;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s['label'] as String,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        Text('$val / $max',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        Container(height: 8, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(4))),
                        FractionallySizedBox(
                          widthFactor: val / max,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(BuildContext context) {
    final achievements = [
      {'icon': '🔥', 'title': 'İlk Seri', 'desc': '7 gün üst üste çalış', 'unlocked': true},
      {'icon': '📚', 'title': 'Okuma Delisi', 'desc': '10 kitap bitir', 'unlocked': false},
      {'icon': '⏱️', 'title': 'Pomodoro Ustası', 'desc': '50 pomodoro tamamla', 'unlocked': false},
      {'icon': '💪', 'title': 'Demir Vücutlu', 'desc': '30 gün spor yap', 'unlocked': true},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.orangeAccent, size: 20),
            SizedBox(width: 8),
            Text('Başarımlar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: achievements.length,
          itemBuilder: (ctx, i) {
            final a = achievements[i];
            final unlocked = a['unlocked'] as bool;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: unlocked ? Colors.orangeAccent.withValues(alpha: 0.4) : AppColors.textSecondary.withValues(alpha: 0.1),
                ),
                boxShadow: unlocked
                    ? [BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.1), blurRadius: 10)]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a['icon'] as String,
                    style: TextStyle(fontSize: 26, color: unlocked ? null : null).merge(
                      unlocked ? null : const TextStyle(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(a['title'] as String,
                      style: TextStyle(
                        color: unlocked ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      )),
                  Text(a['desc'] as String,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                      maxLines: 2),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

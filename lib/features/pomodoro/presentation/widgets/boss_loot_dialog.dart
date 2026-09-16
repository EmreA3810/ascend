import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/features/combat/data/boss_monster.dart';
import 'package:ascend/features/combat/presentation/boss_painter.dart';

/// Savaş Modu Boss zaferinde açılan ganimet ve ödül modalı.
class BossLootDialog extends StatelessWidget {
  final BossMonster boss;
  final int xpEarned;
  final int goldEarned;
  final String? droppedChestRarity;
  final VoidCallback onDismiss;

  const BossLootDialog({
    super.key,
    required this.boss,
    required this.xpEarned,
    required this.goldEarned,
    this.droppedChestRarity,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required BossMonster boss,
    required int xpEarned,
    required int goldEarned,
    String? droppedChestRarity,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BossLootDialog(
        boss: boss,
        xpEarned: xpEarned,
        goldEarned: goldEarned,
        droppedChestRarity: droppedChestRarity,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return Colors.orangeAccent;
      case 'epic':
        return Colors.purpleAccent;
      case 'rare':
        return Colors.blueAccent;
      default:
        return Colors.tealAccent;
    }
  }

  String _getRarityTitle(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return 'Efsanevi Sandık 👑';
      case 'epic':
        return 'Epik Sandık 🔮';
      case 'rare':
        return 'Nadir Sandık 💎';
      default:
        return 'Sıradan Sandık 📦';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF161A26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: boss.accentColor.withValues(alpha: 0.6), width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Üst Zafer Başlığı
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [boss.primaryColor, boss.accentColor],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: boss.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Text(
                '⚔️ BOSS DİZE GETİRİLDİ!',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Boss Avatarı & Zafer Mührü
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: BossAvatar(
                    boss: boss,
                    hpPercentage: 0.0,
                    size: 100,
                  ),
                ),
                Positioned(
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.redAccent, width: 1),
                    ),
                    child: Text(
                      'YENİLDİ',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Boss İsmi
            Text(
              boss.name,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              boss.defeatQuote,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Ödüller Kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Text(
                    'KAZANILAN GANİMET',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // XP
                      _buildRewardPill(
                        icon: Icons.bolt_rounded,
                        color: AppColors.primary,
                        label: '+$xpEarned XP',
                      ),
                      // Altın
                      _buildRewardPill(
                        icon: Icons.monetization_on_rounded,
                        color: AppColors.gold,
                        label: '+$goldEarned Altın',
                      ),
                      // FOC Stat
                      _buildRewardPill(
                        icon: Icons.psychology_rounded,
                        color: Colors.cyanAccent,
                        label: '+1 FOC',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Sandık Düşüşü Varsa
            if (droppedChestRarity != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getRarityColor(droppedChestRarity!).withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _getRarityColor(droppedChestRarity!).withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_rounded, color: _getRarityColor(droppedChestRarity!), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NADİR GANİMET DÜŞTÜ!',
                            style: GoogleFonts.inter(
                              color: _getRarityColor(droppedChestRarity!),
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            _getRarityTitle(droppedChestRarity!),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 22),

            // Topla Butonu
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: onDismiss,
                child: Text(
                  'Ganimetleri Topla',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardPill({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

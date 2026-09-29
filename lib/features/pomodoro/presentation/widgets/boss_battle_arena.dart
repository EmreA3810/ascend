import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/features/combat/data/boss_monster.dart';
import 'package:ascend/features/combat/data/boss_catalog.dart';
import 'package:ascend/features/combat/domain/combat_calculator.dart';
import 'package:ascend/features/combat/presentation/boss_painter.dart';
import 'package:ascend/features/combat/presentation/hit_debris_widget.dart';
import 'package:ascend/features/character/presentation/character_painter.dart';

/// Savaş Modu Boss Arenası Widget'ı.
/// Karakter, Boss sprite'ı, dinamik hasar/çatlak efektleri,
/// kılıç savurma/vuruş animasyonu ve HP barını barındırır.
class BossBattleArena extends StatelessWidget {
  final BossMonster boss;
  final int secondsLeft;
  final int totalSeconds;
  final int maxHp;
  final bool isRunning;
  final bool isAttacking;
  final bool isBossHit;
  final Map<String, String> equippedItems;
  final ValueChanged<BossMonster> onBossChanged;
  final VoidCallback? onManualAttack;

  const BossBattleArena({
    super.key,
    required this.boss,
    required this.secondsLeft,
    required this.totalSeconds,
    required this.maxHp,
    required this.isRunning,
    required this.isAttacking,
    required this.isBossHit,
    required this.equippedItems,
    required this.onBossChanged,
    this.onManualAttack,
  });

  void _showBossPicker(BuildContext context) {
    if (isRunning) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161A26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final all = BossCatalog.getAllBosses();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '⚔️ Karşılaşılacak Boss Seç',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: all.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final m = all[i];
                    final isSelected = m.id == boss.id;
                    return InkWell(
                      onTap: () {
                        onBossChanged(m);
                        Navigator.of(ctx).pop();
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? m.primaryColor.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? m.accentColor : Colors.white12,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 38,
                              height: 38,
                              child: BossAvatar(
                                boss: m,
                                hpPercentage: 1.0,
                                size: 38,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.name,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    m.title,
                                    style: GoogleFonts.inter(
                                      color: Colors.white60,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, color: m.accentColor, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pürüzsüz can barı: Kalan süreye göre her saniye akıcı olarak azalır
    final currentHp = CombatCalculator.calculateRemainingHp(
      currentSecondsLeft: secondsLeft,
      totalSeconds: totalSeconds,
      maxHp: maxHp,
    );
    final hpPercent = maxHp > 0 ? (currentHp / maxHp).clamp(0.0, 1.0) : 0.0;
    final dpm = CombatCalculator.calculateDamagePerMinute(
      totalSeconds: totalSeconds,
      maxHp: maxHp,
    );
    final totalHits = (totalSeconds / 10).floor();
    final singleHitDmg = totalHits > 0 ? (maxHp / totalHits).round().clamp(1, 999) : 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isBossHit ? Colors.redAccent : boss.primaryColor).withValues(alpha: 0.16),
            AppColors.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isBossHit
              ? Colors.redAccent
              : boss.primaryColor.withValues(alpha: 0.35),
          width: isBossHit ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isBossHit ? Colors.redAccent : boss.primaryColor).withValues(alpha: 0.12),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // Savaş Sahnesi: Karakter Saldırısı ve Canavar Çarpışması (Kompakt: 75px yükseklik, çubuksuz)
          SizedBox(
            height: 75,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- 1. KAHRAMAN KARAKTER ---
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOutCubic,
                      offset: isAttacking ? const Offset(0.35, -0.04) : Offset.zero,
                      child: Transform.rotate(
                        angle: isAttacking ? -0.12 : 0.0,
                        child: SizedBox(
                          width: 65,
                          height: 75,
                          child: CharacterAvatar(
                            equippedItems: equippedItems,
                            size: 65,
                          ),
                        ),
                      ),
                    ),

                    // --- 2. MERKEZ KILIÇ KESİŞİ DALGASI ---
                    SizedBox(
                      width: 36,
                      height: 50,
                      child: Center(
                        child: (isAttacking || isBossHit)
                            ? CustomPaint(
                                size: const Size(36, 50),
                                painter: _SlashArcPainter(color: Colors.amberAccent),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),

                    // --- 3. CANAVAR ---
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        AnimatedScale(
                          duration: const Duration(milliseconds: 140),
                          scale: isBossHit ? 0.90 : 1.0,
                          child: SizedBox(
                            width: 75,
                            height: 75,
                            child: BossHitDebrisWidget(
                              boss: boss,
                              isHit: isBossHit,
                              child: BossAvatar(
                                boss: boss,
                                hpPercentage: hpPercent,
                                isHit: isBossHit,
                                size: 70,
                              ),
                            ),
                          ),
                        ),

                        // Hasar Puanı Popup (Floating combat text)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          top: isBossHit ? -12 : 6,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 220),
                            opacity: isBossHit ? 1.0 : 0.0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.red.shade900,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.amberAccent, width: 1.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Text(
                                '-$singleHitDmg HP!',
                                style: GoogleFonts.outfit(
                                  color: Colors.amberAccent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 2. ORTA: DEĞİŞTİR BUTONU, SAĞ: BOSS İSMİ (Boss karakterinin altına)
          SizedBox(
            height: 28,
            child: Stack(
              children: [
                // ORTA: Değiştir Butonu
                Align(
                  alignment: Alignment.center,
                  child: InkWell(
                    onTap: isRunning ? null : () => _showBossPicker(context),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isRunning
                            ? Colors.white.withValues(alpha: 0.04)
                            : boss.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isRunning
                              ? Colors.white12
                              : boss.accentColor.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRunning ? Icons.lock_outline_rounded : Icons.swap_horiz_rounded,
                            color: isRunning ? Colors.white38 : boss.accentColor,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isRunning ? 'Savaşta' : 'Değiştir',
                            style: GoogleFonts.inter(
                              color: isRunning ? Colors.white38 : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // SAĞ: Boss İsmi ve Rozeti (Boss karakterinin tam altına hizalı)
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        boss.name,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: (hpPercent < 0.3 ? Colors.redAccent : boss.accentColor).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: (hpPercent < 0.3 ? Colors.redAccent : boss.accentColor).withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          hpPercent < 0.3 ? 'ÖFKELİ 💥' : 'BOSS',
                          style: GoogleFonts.inter(
                            color: hpPercent < 0.3 ? Colors.redAccent : boss.accentColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 8.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),

          // 3. CAN (HP) & HASAR BİLGİSİ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    color: hpPercent < 0.3 ? Colors.redAccent : Colors.red,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'CAN (HP): $currentHp / $maxHp',
                    style: GoogleFonts.inter(
                      color: hpPercent < 0.3 ? Colors.redAccent : Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
              Text(
                '⚔️ ${dpm.toStringAsFixed(1)} Hasar / dk',
                style: GoogleFonts.inter(
                  color: boss.accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // 4. Dinamik HP Çubuğu (Soldan Sabitli, Sadece Sağdan Sola Azalır)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 7,
              width: double.infinity,
              color: Colors.black.withValues(alpha: 0.45),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      width: constraints.maxWidth * hpPercent,
                      height: 7,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: hpPercent < 0.3
                              ? [Colors.redAccent, Colors.orangeAccent]
                              : [boss.primaryColor, boss.accentColor],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kılıç savurma anında ortaya çıkan neon kavisli kesik efekti
class _SlashArcPainter extends CustomPainter {
  final Color color;

  _SlashArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.85);
    path.quadraticBezierTo(
      size.width * 0.55,
      size.height * 0.45,
      size.width * 0.9,
      size.height * 0.15,
    );
    canvas.drawPath(path, glowPaint);

    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
    // Can yalnızca kahramanımız vuruş gerçekleştirdiğinde senkronize olarak azalır (10sn periyot)
    final currentHp = CombatCalculator.calculateRemainingHp(
      currentSecondsLeft: secondsLeft,
      totalSeconds: totalSeconds,
      maxHp: maxHp,
      attackInterval: 10,
    );
    final hpPercent = maxHp > 0 ? (currentHp / maxHp).clamp(0.0, 1.0) : 0.0;
    final dpm = CombatCalculator.calculateDamagePerMinute(
      totalSeconds: totalSeconds,
      maxHp: maxHp,
    );
    final totalHits = (totalSeconds / 10).floor();
    final singleHitDmg = totalHits > 0 ? (maxHp / totalHits).round().clamp(1, 999) : 1;

    return Column(
      children: [
        // Boss Kartı & HP Barı
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isBossHit ? Colors.red.withValues(alpha: 0.3) : boss.primaryColor.withValues(alpha: 0.18),
                AppColors.cardBackground,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isBossHit ? Colors.redAccent : boss.primaryColor.withValues(alpha: 0.4),
              width: isBossHit ? 1.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isBossHit ? Colors.red.withValues(alpha: 0.25) : boss.primaryColor.withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst: Boss Başlığı ve Seçim Butonu
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: boss.primaryColor.withValues(alpha: 0.25),
                      border: Border.all(color: boss.accentColor.withValues(alpha: 0.6)),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: BossAvatar(
                          boss: boss,
                          hpPercentage: hpPercent,
                          isHit: isBossHit,
                          size: 42,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              boss.name,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: boss.accentColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                hpPercent < 0.3 ? 'ÖFKELİ 💥' : 'BOSS',
                                style: GoogleFonts.inter(
                                  color: hpPercent < 0.3 ? Colors.redAccent : boss.accentColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          boss.title,
                          style: GoogleFonts.inter(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (!isRunning)
                    InkWell(
                      onTap: () => _showBossPicker(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.swap_horiz_rounded, color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Değiştir',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Can Barı Başlığı & Sayacı
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CAN (HP): $currentHp / $maxHp',
                    style: GoogleFonts.inter(
                      color: hpPercent < 0.3 ? Colors.redAccent : Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
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
              const SizedBox(height: 6),

              // Dinamik HP Çubuğu
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 10,
                  color: Colors.black38,
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: hpPercent,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: hpPercent < 0.3
                                  ? [Colors.redAccent, Colors.orangeAccent]
                                  : [boss.primaryColor, boss.accentColor],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Savaş Sahnesi: Karakter Saldırısı ve Canavar Çarpışması
        Container(
            height: 145,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.4, 0),
                radius: 1.1,
                colors: [
                  (isBossHit ? Colors.redAccent : boss.primaryColor).withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isBossHit
                    ? Colors.redAccent.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Zemin çizgisi / Arenanın derinlik ışıltısı
                Positioned(
                  bottom: 6,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: [
                          Colors.cyanAccent.withValues(alpha: 0.15),
                          boss.accentColor.withValues(alpha: 0.25),
                        ],
                      ),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- 1. KAHRAMAN KARAKTER ---
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOutCubic,
                      offset: isAttacking ? const Offset(0.38, -0.05) : Offset.zero,
                      child: Transform.rotate(
                        angle: isAttacking ? -0.14 : 0.0,
                        child: SizedBox(
                          width: 95,
                          height: 110,
                          child: CharacterAvatar(
                            equippedItems: equippedItems,
                            size: 95,
                          ),
                        ),
                      ),
                    ),

                    // --- 2. MERKEZ KILIÇ KESİŞİ DALGASI ---
                    SizedBox(
                      width: 50,
                      height: 100,
                      child: Center(
                        child: (isAttacking || isBossHit)
                            ? CustomPaint(
                                size: const Size(50, 70),
                                painter: _SlashArcPainter(color: Colors.amberAccent),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),

                    // --- 3. CANAVAR (FİZİKSEL PARÇA PATLAMASI İLE) ---
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        AnimatedScale(
                          duration: const Duration(milliseconds: 140),
                          scale: isBossHit ? 0.90 : 1.0,
                          child: SizedBox(
                            width: 110,
                            height: 110,
                            child: BossHitDebrisWidget(
                              boss: boss,
                              isHit: isBossHit,
                              child: BossAvatar(
                                boss: boss,
                                hpPercentage: hpPercent,
                                isHit: isBossHit,
                                size: 110,
                              ),
                            ),
                          ),
                        ),

                        // Hasar Puanı Popup (Floating combat text)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          top: isBossHit ? -14 : 10,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 220),
                            opacity: isBossHit ? 1.0 : 0.0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade900,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amberAccent, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Text(
                                '-$singleHitDmg HP!',
                                style: GoogleFonts.outfit(
                                  color: Colors.amberAccent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
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
      ],
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

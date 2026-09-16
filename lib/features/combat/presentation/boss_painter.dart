import 'dart:math';
import 'package:flutter/material.dart';
import '../data/boss_monster.dart';

/// Canavarın (Golem, Demon, Dragon, Wraith vb.) tam teşekküllü karakter sprite'ı
/// ve can azaldıkça değişen görsel durum efektleri (çatlaklar, duman, yorgunluk, parıltı).
class BossAvatar extends StatefulWidget {
  final BossMonster boss;
  final double hpPercentage; // 0.0 - 1.0
  final bool isHit;
  final double size;

  const BossAvatar({
    super.key,
    required this.boss,
    required this.hpPercentage,
    this.isHit = false,
    this.size = 130,
  });

  @override
  State<BossAvatar> createState() => _BossAvatarState();
}

class _BossAvatarState extends State<BossAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Can azaldıkça animasyon nefes alıp verme hızı artar (tükeniş/hiddet hissi)
    final isCritical = widget.hpPercentage < 0.3;
    final isWounded = widget.hpPercentage < 0.7;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: BossPainter(
              boss: widget.boss,
              hpPercentage: widget.hpPercentage,
              isHit: widget.isHit,
              isCritical: isCritical,
              isWounded: isWounded,
              animValue: _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class BossPainter extends CustomPainter {
  final BossMonster boss;
  final double hpPercentage;
  final bool isHit;
  final bool isCritical;
  final bool isWounded;
  final double animValue;

  BossPainter({
    required this.boss,
    required this.hpPercentage,
    required this.isHit,
    required this.isCritical,
    required this.isWounded,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    final center = Offset(size.width / 2, size.height / 2);
    final scale = min(size.width / 120.0, size.height / 120.0);
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);

    // Vuruş aldığında sarsıntı
    if (isHit) {
      canvas.translate(sin(animValue * 40 * pi) * 4.0, 0);
    }

    // Nefes alma / süzülme hareketi (Kritik canda daha hızlı ve kesik kesik)
    final speedMultiplier = isCritical ? 2.8 : 1.0;
    final breath = sin(animValue * 2 * pi * speedMultiplier) * (isCritical ? 3.0 : 2.0);

    // 1. Zemin Gölgesi / Aura
    _drawShadowAndAura(canvas, breath);

    // 2. Canavar Türüne Göre Karakter Çizimi
    switch (boss.id) {
      case 'sloth_titan':
      case 'fatigue_golem':
        _drawStoneGolem(canvas, breath);
        break;
      case 'procrastination_demon':
        _drawDemon(canvas, breath);
        break;
      case 'distraction_dragon':
        _drawDragon(canvas, breath);
        break;
      case 'bug_queen':
        _drawBugQueen(canvas, breath);
        break;
      case 'anxiety_wraith':
        _drawWraith(canvas, breath);
        break;
      case 'time_thief':
      default:
        _drawShadowAssassin(canvas, breath);
        break;
    }

    // 3. Can Kaybı Efektleri (Çatlaklar, duman, yara izleri)
    if (isWounded) {
      _drawDamageEffects(canvas, breath);
    }

    // 4. Vuruş Anında Beyaz/Kırmızı Parlama Flaşı
    if (isHit) {
      final flashPaint = Paint()
        ..color = Colors.redAccent.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(0, -10 + breath), 45, flashPaint);
    }

    canvas.restore();
  }

  void _drawShadowAndAura(Canvas canvas, double breath) {
    // Taban gölgesi
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawOval(const Rect.fromLTWH(-35, 42, 70, 14), shadowPaint);

    // Canavarın arkasındaki tematik enerji aurası
    final auraColor = isCritical
        ? Colors.redAccent
        : isHit
            ? Colors.white
            : boss.primaryColor;
    final auraRadius = isCritical ? (42.0 + sin(animValue * 10) * 4) : 38.0;

    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          auraColor.withValues(alpha: isCritical ? 0.45 : 0.22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(0, -10 + breath), radius: auraRadius + 20));

    canvas.drawCircle(Offset(0, -10 + breath), auraRadius + 20, auraPaint);
  }

  // --- 1. TAŞ & MAGMA GOLEM (Sloth Titan / Fatigue Golem) ---
  void _drawStoneGolem(Canvas canvas, double breath) {
    final isMagma = boss.id == 'fatigue_golem';
    final rockColor = isMagma ? const Color(0xFF372826) : const Color(0xFF4A4441);
    final coreColor = isMagma ? const Color(0xFFFF5722) : const Color(0xFF00E5FF);

    final rockPaint = Paint()
      ..color = rockColor
      ..style = PaintingStyle.fill;
    final rockOutline = Paint()
      ..color = rockColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final yOffset = breath;

    // Ayaklar / Kaya tabanı
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-28, 28 + yOffset, 22, 16), const Radius.circular(6)), rockPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(6, 28 + yOffset, 22, 16), const Radius.circular(6)), rockPaint);

    // Devasa Kaya Gövde (Torso)
    final torsoPath = Path()
      ..moveTo(-30, 26 + yOffset)
      ..lineTo(30, 26 + yOffset)
      ..lineTo(36, -8 + yOffset)
      ..lineTo(-36, -8 + yOffset)
      ..close();
    canvas.drawPath(torsoPath, rockPaint);
    canvas.drawPath(torsoPath, rockOutline);

    // Göğüsteki Parlayan Enerji Kristali / Magma Çekirdeği
    final corePaint = Paint()
      ..color = coreColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
    canvas.drawCircle(Offset(0, 10 + yOffset), 9, corePaint);

    // Kaya Omuzluklar
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-48, -14 + yOffset, 22, 26), const Radius.circular(8)), rockPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(26, -14 + yOffset, 22, 26), const Radius.circular(8)), rockPaint);

    // Kaya Kollar & Yumruklar
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-46, 12 + yOffset, 18, 22), const Radius.circular(6)), rockPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(28, 12 + yOffset, 18, 22), const Radius.circular(6)), rockPaint);

    // Chiseled Taş Kafa
    final headRect = RRect.fromRectAndRadius(Rect.fromLTWH(-22, -38 + yOffset, 44, 30), const Radius.circular(10));
    canvas.drawRRect(headRect, rockPaint);
    canvas.drawRRect(headRect, rockOutline);

    // Parlayan Göz Yarıkları
    final eyePaint = Paint()
      ..color = coreColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-14, -26 + yOffset, 9, 5), const Radius.circular(2)), eyePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(5, -26 + yOffset, 9, 5), const Radius.circular(2)), eyePaint);

    // Alın Zırh Plakası / Boynuzumsu Taş Çıkıntı
    final crownPath = Path()
      ..moveTo(-16, -38 + yOffset)
      ..lineTo(0, -48 + yOffset)
      ..lineTo(16, -38 + yOffset)
      ..close();
    canvas.drawPath(crownPath, rockPaint);
  }

  // --- 2. ERTELEME İBLİSİ (Procrastination Demon) ---
  void _drawDemon(Canvas canvas, double breath) {
    const skinColor = Color(0xFF211424);
    final hornColor = const Color(0xFFD32F2F);
    final eyeColor = const Color(0xFFFF1744);

    final skinPaint = Paint()..color = skinColor..style = PaintingStyle.fill;
    final yOffset = breath;

    // Şeytani Kanatlar / Gölgeler
    final wingPath = Path();
    wingPath.moveTo(-20, yOffset);
    wingPath.lineTo(-55, -28 + yOffset);
    wingPath.lineTo(-40, 10 + yOffset);
    wingPath.lineTo(-20, 20 + yOffset);
    wingPath.close();
    canvas.drawPath(wingPath, Paint()..color = const Color(0xFF140A18)..style = PaintingStyle.fill);

    final rightWing = Path();
    rightWing.moveTo(20, yOffset);
    rightWing.lineTo(55, -28 + yOffset);
    rightWing.lineTo(40, 10 + yOffset);
    rightWing.lineTo(20, 20 + yOffset);
    rightWing.close();
    canvas.drawPath(rightWing, Paint()..color = const Color(0xFF140A18)..style = PaintingStyle.fill);

    // Gövde
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-22, -6 + yOffset, 44, 40), const Radius.circular(10)), skinPaint);

    // Göğüsteki Şeytani Kor Rünü
    final runePaint = Paint()
      ..color = hornColor.withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
    canvas.drawCircle(Offset(0, 14 + yOffset), 8, runePaint);

    // Kafa
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-20, -38 + yOffset, 40, 32), const Radius.circular(10)), skinPaint);

    // Büyük Kavisli Şeytan Boynuzları
    final hornPaint = Paint()..color = hornColor..style = PaintingStyle.fill;
    final leftHorn = Path()
      ..moveTo(-12, -36 + yOffset)
      ..quadraticBezierTo(-34, -56 + yOffset, -38, -32 + yOffset)
      ..quadraticBezierTo(-24, -40 + yOffset, -8, -34 + yOffset)
      ..close();
    canvas.drawPath(leftHorn, hornPaint);

    final rightHorn = Path()
      ..moveTo(12, -36 + yOffset)
      ..quadraticBezierTo(34, -56 + yOffset, 38, -32 + yOffset)
      ..quadraticBezierTo(24, -40 + yOffset, 8, -34 + yOffset)
      ..close();
    canvas.drawPath(rightHorn, hornPaint);

    // Kırmızı Kötücül Gözler
    final eyePaint = Paint()
      ..color = eyeColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
    canvas.drawOval(Rect.fromLTWH(-14, -26 + yOffset, 9, 6), eyePaint);
    canvas.drawOval(Rect.fromLTWH(5, -26 + yOffset, 9, 6), eyePaint);
  }

  // --- 3. DİKKAT DAĞINIKLIĞI EJDERİ (Distraction Dragon) ---
  void _drawDragon(Canvas canvas, double breath) {
    const scaleColor = Color(0xFF4A148C);
    const accentColor = Color(0xFF00E5FF);
    final dragonPaint = Paint()..color = scaleColor..style = PaintingStyle.fill;
    final yOffset = breath;

    // Ejderha Kanatları
    final wingPaint = Paint()..color = const Color(0xFF311B92)..style = PaintingStyle.fill;
    final leftWing = Path()
      ..moveTo(-15, 0 + yOffset)
      ..lineTo(-52, -32 + yOffset)
      ..lineTo(-44, -6 + yOffset)
      ..lineTo(-48, 16 + yOffset)
      ..close();
    canvas.drawPath(leftWing, wingPaint);

    final rightWing = Path()
      ..moveTo(15, 0 + yOffset)
      ..lineTo(52, -32 + yOffset)
      ..lineTo(44, -6 + yOffset)
      ..lineTo(48, 16 + yOffset)
      ..close();
    canvas.drawPath(rightWing, wingPaint);

    // Gövde
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-22, -4 + yOffset, 44, 38), const Radius.circular(14)), dragonPaint);

    // Göğüs Zırh Pulları
    final chestPaint = Paint()..color = const Color(0xFF7B1FA2)..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-12, 6 + yOffset, 24, 20), const Radius.circular(8)), chestPaint);

    // Ejderha Kafası ve Çenesi
    final headPath = Path()
      ..moveTo(-18, -34 + yOffset)
      ..lineTo(0, -44 + yOffset)
      ..lineTo(18, -34 + yOffset)
      ..lineTo(20, -12 + yOffset)
      ..lineTo(0, -4 + yOffset)
      ..lineTo(-20, -12 + yOffset)
      ..close();
    canvas.drawPath(headPath, dragonPaint);

    // Ejderha Boynuzları
    final hornPaint = Paint()..color = accentColor..style = PaintingStyle.fill;
    final leftHorn = Path()
      ..moveTo(-12, -34 + yOffset)
      ..lineTo(-28, -52 + yOffset)
      ..lineTo(-8, -40 + yOffset)
      ..close();
    canvas.drawPath(leftHorn, hornPaint);

    final rightHorn = Path()
      ..moveTo(12, -34 + yOffset)
      ..lineTo(28, -52 + yOffset)
      ..lineTo(8, -40 + yOffset)
      ..close();
    canvas.drawPath(rightHorn, hornPaint);

    // Siyan Parlayan Yırtıcı Gözler
    final eyePaint = Paint()
      ..color = accentColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
    canvas.drawOval(Rect.fromLTWH(-14, -24 + yOffset, 8, 4), eyePaint);
    canvas.drawOval(Rect.fromLTWH(6, -24 + yOffset, 8, 4), eyePaint);
  }

  // --- 4. HATA BÖCEĞİ KRALİÇESİ (Bug Queen) ---
  void _drawBugQueen(Canvas canvas, double breath) {
    const carapaceColor = Color(0xFF004D40);
    const neonGreen = Color(0xFF76FF03);
    final bodyPaint = Paint()..color = carapaceColor..style = PaintingStyle.fill;
    final yOffset = breath;

    // Yan Kıskaçlar / Bacaklar
    final legPaint = Paint()
      ..color = const Color(0xFF00796B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(-22, 10 + yOffset), Offset(-46, -6 + yOffset), legPaint);
    canvas.drawLine(Offset(-46, -6 + yOffset), Offset(-48, 24 + yOffset), legPaint);

    canvas.drawLine(Offset(22, 10 + yOffset), Offset(46, -6 + yOffset), legPaint);
    canvas.drawLine(Offset(46, -6 + yOffset), Offset(48, 24 + yOffset), legPaint);

    // Zırhlı Böcek Gövdesi
    canvas.drawOval(Rect.fromLTWH(-24, -8 + yOffset, 48, 42), bodyPaint);

    // Kafa
    canvas.drawOval(Rect.fromLTWH(-20, -36 + yOffset, 40, 30), bodyPaint);

    // Kraliçe Antenleri
    final antPaint = Paint()
      ..color = neonGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final leftAnt = Path()
      ..moveTo(-10, -34 + yOffset)
      ..quadraticBezierTo(-24, -58 + yOffset, -36, -50 + yOffset);
    canvas.drawPath(leftAnt, antPaint);

    final rightAnt = Path()
      ..moveTo(10, -34 + yOffset)
      ..quadraticBezierTo(24, -58 + yOffset, 36, -50 + yOffset);
    canvas.drawPath(rightAnt, antPaint);

    // Neon Yeşil Petek Gözler
    final eyePaint = Paint()
      ..color = neonGreen
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
    canvas.drawOval(Rect.fromLTWH(-16, -26 + yOffset, 10, 10), eyePaint);
    canvas.drawOval(Rect.fromLTWH(6, -26 + yOffset, 10, 10), eyePaint);
  }

  // --- 5. ODAKSIZLIK HORTLAĞI (Anxiety Wraith) ---
  void _drawWraith(Canvas canvas, double breath) {
    const cloakColor = Color(0xFF1A237E);
    const ghostViolet = Color(0xFFB388FF);
    final yOffset = breath * 1.5; // Hayalet daha çok dalgalanır

    // Dalgalanan Hayalet Pelerini
    final wraithPath = Path()
      ..moveTo(0, -42 + yOffset)
      ..quadraticBezierTo(-32, -30 + yOffset, -30, 14 + yOffset)
      ..lineTo(-24, 34 + yOffset)
      ..lineTo(-12, 24 + yOffset)
      ..lineTo(0, 36 + yOffset)
      ..lineTo(12, 24 + yOffset)
      ..lineTo(24, 34 + yOffset)
      ..lineTo(30, 14 + yOffset)
      ..quadraticBezierTo(32, -30 + yOffset, 0, -42 + yOffset)
      ..close();

    canvas.drawPath(wraithPath, Paint()..color = cloakColor..style = PaintingStyle.fill);

    // Başlık İçi Karanlık Boşluk
    final hoodVoid = Path()
      ..moveTo(0, -36 + yOffset)
      ..quadraticBezierTo(-18, -26 + yOffset, -16, -6 + yOffset)
      ..quadraticBezierTo(0, 4 + yOffset, 16, -6 + yOffset)
      ..quadraticBezierTo(18, -26 + yOffset, 0, -36 + yOffset)
      ..close();
    canvas.drawPath(hoodVoid, Paint()..color = Colors.black..style = PaintingStyle.fill);

    // Boşlukta Yüzen Hortlak Gözleri
    final eyePaint = Paint()
      ..color = ghostViolet
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
    canvas.drawCircle(Offset(-7, -14 + yOffset), 4, eyePaint);
    canvas.drawCircle(Offset(7, -14 + yOffset), 4, eyePaint);
  }

  // --- 6. ZAMAN HIRSIZI GÖLGE (Time Thief Assassin) ---
  void _drawShadowAssassin(Canvas canvas, double breath) {
    const ninjaBlack = Color(0xFF263238);
    const goldGlow = Color(0xFFFFD54F);
    final yOffset = breath;

    // Gövde & Pelerin
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-20, -4 + yOffset, 40, 36), const Radius.circular(8)), Paint()..color = ninjaBlack..style = PaintingStyle.fill);

    // Kafa & Maske
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-18, -36 + yOffset, 36, 30), const Radius.circular(8)), Paint()..color = ninjaBlack..style = PaintingStyle.fill);

    // Başlık Kıvrımı
    final hoodPath = Path()
      ..moveTo(-18, -36 + yOffset)
      ..lineTo(0, -46 + yOffset)
      ..lineTo(18, -36 + yOffset)
      ..close();
    canvas.drawPath(hoodPath, Paint()..color = const Color(0xFF1E272C)..style = PaintingStyle.fill);

    // Altın Vizör / Göz Maskesi
    final visorPaint = Paint()
      ..color = goldGlow
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-12, -22 + yOffset, 24, 6), const Radius.circular(3)), visorPaint);
  }

  // --- 3. CAN KAYBI EFEKTLERİ (Çatlaklar, Kıvılcımlar, Yorgunluk) ---
  void _drawDamageEffects(Canvas canvas, double breath) {
    final yOffset = breath;

    // Canavar üzerinde savaş çatlakları
    final crackPaint = Paint()
      ..color = isCritical ? Colors.redAccent : Colors.orangeAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCritical ? 2.2 : 1.4
      ..strokeCap = StrokeCap.round
      ..maskFilter = isCritical ? const MaskFilter.blur(BlurStyle.solid, 2) : null;

    final crack1 = Path()
      ..moveTo(-10, -4 + yOffset)
      ..lineTo(-4, 6 + yOffset)
      ..lineTo(-12, 16 + yOffset)
      ..lineTo(-6, 24 + yOffset);
    canvas.drawPath(crack1, crackPaint);

    if (isCritical) {
      final crack2 = Path()
        ..moveTo(12, -18 + yOffset)
        ..lineTo(4, -8 + yOffset)
        ..lineTo(10, 4 + yOffset);
      canvas.drawPath(crack2, crackPaint);

      // Yükselen duman / kıvılcım parçacıkları
      final sparkPaint = Paint()
        ..color = (animValue > 0.5) ? Colors.orangeAccent : Colors.redAccent
        ..style = PaintingStyle.fill;
      final sparkY1 = -45 + yOffset - (animValue * 20);
      final sparkY2 = -35 + yOffset - ((animValue + 0.5) % 1.0 * 20);
      canvas.drawCircle(Offset(-16 + sin(animValue * 6) * 6, sparkY1), 2.5, sparkPaint);
      canvas.drawCircle(Offset(14 + cos(animValue * 6) * 6, sparkY2), 2.0, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BossPainter oldDelegate) {
    return oldDelegate.animValue != animValue ||
        oldDelegate.hpPercentage != hpPercentage ||
        oldDelegate.isHit != isHit ||
        oldDelegate.boss.id != boss.id;
  }
}

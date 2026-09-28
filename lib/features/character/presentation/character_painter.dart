import 'dart:math';
import 'package:flutter/material.dart';
import '../data/loot_pool.dart';

class CharacterAvatar extends StatefulWidget {
  final Map<String, String> equippedItems;
  final double size;
  final double? width;
  final double? height;
  const CharacterAvatar({
    super.key,
    required this.equippedItems,
    this.size = 150,
    this.width,
    this.height,
  });

  @override
  State<CharacterAvatar> createState() => _CharacterAvatarState();
}

class _CharacterAvatarState extends State<CharacterAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width ?? widget.size;
    final h = widget.height ?? widget.size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: w,
          height: h,
          child: CustomPaint(
            size: Size(w, h),
            painter: CharacterPainter(
              equippedItems: widget.equippedItems,
              animationValue: _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class CharacterPainter extends CustomPainter {
  final Map<String, String> equippedItems;
  final double animationValue;

  CharacterPainter({
    required this.equippedItems,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Auto-scale to ensure head, hats, body, legs, boots and shadow are completely visible
    final scale = min(size.width / 58.0, size.height / 116.0);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    const center = Offset(0, 3.0);
    
    // Nefes alma animasyonu hesabı (Sinüs dalgası: -2.0 ile +2.0 piksel)
    final breath = sin(animationValue * 2 * pi) * 1.5;

    // Fırçalar
    final skinPaint = Paint()
      ..color = const Color(0xFFFFD1A9) // Açık ten rengi
      ..style = PaintingStyle.fill;
    
    final eyePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Yer gölgesi çizimi
    canvas.drawOval(
      Rect.fromLTRB(center.dx - 20, center.dy + 47, center.dx + 20, center.dy + 52),
      shadowPaint,
    );

    // --- 1. BACAKLAR & PANTOLON ---
    final pantsItem = LootPool.getItemById(equippedItems['pants'] ?? '');
    final Color pantsColor = pantsItem?.color ?? Colors.grey.shade700;
    final String pantsId = pantsItem?.id ?? '';

    // Sol Bacak (Ten)
    final leftLegPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(center.dx - 12, center.dy + 15, center.dx - 4, center.dy + 47),
        const Radius.circular(3),
      ));
    // Sağ Bacak (Ten)
    final rightLegPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(center.dx + 4, center.dy + 15, center.dx + 12, center.dy + 47),
        const Radius.circular(3),
      ));
    
    canvas.drawPath(leftLegPath, skinPaint);
    canvas.drawPath(rightLegPath, skinPaint);

    // Pantolon Çizimi (Kuşanıldıysa bacakları kaplar)
    final pantsPaint = Paint()
      ..color = pantsColor
      ..style = PaintingStyle.fill;

    if (pantsId.isNotEmpty) {
      if (pantsId == 'shorts') {
        // Spor Şort: Bel lastiği ve paça detayları
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 13, center.dy + 12, center.dx - 3, center.dy + 32),
          const Radius.circular(3),
        ), pantsPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx + 3, center.dy + 12, center.dx + 13, center.dy + 32),
          const Radius.circular(3),
        ), pantsPaint);
        // Bel bandı
        final waistPaint = Paint()..color = Colors.grey.shade800..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 14, center.dy + 11, center.dx + 14, center.dy + 15),
          const Radius.circular(2),
        ), waistPaint);
        // Beyaz şort yan çizgisi
        final stripePaint = Paint()..color = Colors.white70..style = PaintingStyle.stroke..strokeWidth = 1.2;
        canvas.drawLine(Offset(center.dx - 12, center.dy + 15), Offset(center.dx - 12, center.dy + 31), stripePaint);
        canvas.drawLine(Offset(center.dx + 12, center.dy + 15), Offset(center.dx + 12, center.dy + 31), stripePaint);
      } else if (pantsId == 'ronin_hakama') {
        // Samuray Hakama: Bacaklara oturan, doğal pileli ve dengeli samuray pantolonu
        // Sol paça
        final leftHakama = Path()
          ..moveTo(center.dx - 14, center.dy + 12)
          ..lineTo(center.dx - 1, center.dy + 12)
          ..lineTo(center.dx - 1, center.dy + 22)
          ..lineTo(center.dx - 2, center.dy + 45)
          ..lineTo(center.dx - 14.5, center.dy + 45)
          ..lineTo(center.dx - 14.5, center.dy + 22)
          ..close();
        // Sağ paça
        final rightHakama = Path()
          ..moveTo(center.dx + 1, center.dy + 12)
          ..lineTo(center.dx + 14, center.dy + 12)
          ..lineTo(center.dx + 14.5, center.dy + 22)
          ..lineTo(center.dx + 14.5, center.dy + 45)
          ..lineTo(center.dx + 2, center.dy + 45)
          ..lineTo(center.dx + 1, center.dy + 22)
          ..close();
        canvas.drawPath(leftHakama, pantsPaint);
        canvas.drawPath(rightHakama, pantsPaint);

        // Geleneksel samuray pileleri (Derinlik gölgeleri)
        final pleatShadow = Paint()..color = Colors.black.withValues(alpha: 0.25)..style = PaintingStyle.stroke..strokeWidth = 1.2;
        // Sol pileler
        canvas.drawLine(Offset(center.dx - 8, center.dy + 17), Offset(center.dx - 8, center.dy + 45), pleatShadow);
        canvas.drawLine(Offset(center.dx - 12, center.dy + 20), Offset(center.dx - 12, center.dy + 44), pleatShadow);
        // Sağ pileler
        canvas.drawLine(Offset(center.dx + 8, center.dy + 17), Offset(center.dx + 8, center.dy + 45), pleatShadow);
        canvas.drawLine(Offset(center.dx + 12, center.dy + 20), Offset(center.dx + 12, center.dy + 44), pleatShadow);

        // Obi (Siyah samuray bel kuşağı)
        final obiPaint = Paint()..color = Colors.black87..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 14, center.dy + 11, center.dx + 14, center.dy + 16),
          const Radius.circular(2),
        ), obiPaint);
        // Kuşak düğümü ve sarkan uçlar
        canvas.drawRect(Rect.fromLTRB(center.dx - 2, center.dy + 13, center.dx + 2, center.dy + 20), obiPaint);
      } else {
        // Uzun pantolon temel gövdesi
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 13, center.dy + 11, center.dx - 3, center.dy + 47),
          const Radius.circular(3),
        ), pantsPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx + 3, center.dy + 11, center.dx + 13, center.dy + 47),
          const Radius.circular(3),
        ), pantsPaint);
        // Bel birleşimi
        canvas.drawRect(Rect.fromLTRB(center.dx - 13, center.dy + 11, center.dx + 13, center.dy + 18), pantsPaint);

        if (pantsId == 'jeans') {
          // Kot dikişleri & Kemer
          final beltPaint = Paint()..color = Colors.brown.shade800..style = PaintingStyle.fill;
          canvas.drawRect(Rect.fromLTRB(center.dx - 13, center.dy + 11, center.dx + 13, center.dy + 15), beltPaint);
          final bucklePaint = Paint()..color = Colors.amber..style = PaintingStyle.fill;
          canvas.drawRect(Rect.fromLTRB(center.dx - 2, center.dy + 11.5, center.dx + 2, center.dy + 14.5), bucklePaint);
          // Diz eskitme çizgisi
          final jeanStitch = Paint()..color = Colors.lightBlue.withValues(alpha: 0.35)..style = PaintingStyle.fill;
          canvas.drawOval(Rect.fromLTRB(center.dx - 11, center.dy + 27, center.dx - 5, center.dy + 31), jeanStitch);
          canvas.drawOval(Rect.fromLTRB(center.dx + 5, center.dy + 27, center.dx + 11, center.dy + 31), jeanStitch);
        } else if (pantsId == 'trousers') {
          // Kumaş pantolon ütü çizgisi ve kemer
          final beltPaint = Paint()..color = Colors.black87..style = PaintingStyle.fill;
          canvas.drawRect(Rect.fromLTRB(center.dx - 13, center.dy + 11, center.dx + 13, center.dy + 15), beltPaint);
          final creasePaint = Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 0.8;
          canvas.drawLine(Offset(center.dx - 8, center.dy + 17), Offset(center.dx - 8, center.dy + 46), creasePaint);
          canvas.drawLine(Offset(center.dx + 8, center.dy + 17), Offset(center.dx + 8, center.dy + 46), creasePaint);
        } else if (pantsId == 'cargo_pants') {
          // Kargo cepleri
          final pocketPaint = Paint()..color = pantsColor.withValues(alpha: 0.85)..style = PaintingStyle.fill;
          final flapPaint = Paint()..color = Colors.black45..style = PaintingStyle.fill;
          // Sol cep
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(center.dx - 15, center.dy + 23, center.dx - 11, center.dy + 33), const Radius.circular(2)), pocketPaint);
          canvas.drawRect(Rect.fromLTRB(center.dx - 15, center.dy + 23, center.dx - 11, center.dy + 25), flapPaint);
          // Sağ cep
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(center.dx + 11, center.dy + 23, center.dx + 15, center.dy + 33), const Radius.circular(2)), pocketPaint);
          canvas.drawRect(Rect.fromLTRB(center.dx + 11, center.dy + 23, center.dx + 15, center.dy + 25), flapPaint);
        } else if (pantsId == 'steel_greaves') {
          // Çelik Dizlik & Baldır Zırhı
          final steelPaint = Paint()..color = Colors.blueGrey.shade200..style = PaintingStyle.fill;
          final steelBorder = Paint()..color = Colors.blueGrey.shade800..style = PaintingStyle.stroke..strokeWidth = 1.0;
          // Dizlikler
          canvas.drawCircle(Offset(center.dx - 8, center.dy + 28), 4.5, steelPaint);
          canvas.drawCircle(Offset(center.dx - 8, center.dy + 28), 4.5, steelBorder);
          canvas.drawCircle(Offset(center.dx + 8, center.dy + 28), 4.5, steelPaint);
          canvas.drawCircle(Offset(center.dx + 8, center.dy + 28), 4.5, steelBorder);
          // Baldır levhaları
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(center.dx - 11, center.dy + 34, center.dx - 5, center.dy + 45), const Radius.circular(2)), steelPaint);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(center.dx + 5, center.dy + 34, center.dx + 11, center.dy + 45), const Radius.circular(2)), steelPaint);
        } else if (pantsId == 'leather_greaves') {
          // Deri bağcıklar ve korumalık
          final leatherDark = Paint()..color = Colors.brown.shade900..style = PaintingStyle.fill;
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(center.dx - 12, center.dy + 24, center.dx - 4, center.dy + 33), const Radius.circular(2)), leatherDark);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(center.dx + 4, center.dy + 24, center.dx + 12, center.dy + 33), const Radius.circular(2)), leatherDark);
          // Deri çapraz bağlar
          final strap = Paint()..color = Colors.amber.shade700..style = PaintingStyle.stroke..strokeWidth = 1.0;
          canvas.drawLine(Offset(center.dx - 11, center.dy + 36), Offset(center.dx - 5, center.dy + 40), strap);
          canvas.drawLine(Offset(center.dx - 11, center.dy + 42), Offset(center.dx - 5, center.dy + 46), strap);
          canvas.drawLine(Offset(center.dx + 5, center.dy + 36), Offset(center.dx + 11, center.dy + 40), strap);
          canvas.drawLine(Offset(center.dx + 5, center.dy + 42), Offset(center.dx + 11, center.dy + 46), strap);
        } else if (pantsId == 'shadow_pants') {
          // Ninja baldır sarımları (Kyahan)
          final wrapPaint = Paint()..color = Colors.deepPurple.shade900..style = PaintingStyle.fill;
          final tiePaint = Paint()..color = Colors.purpleAccent.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 1.0;
          canvas.drawRect(Rect.fromLTRB(center.dx - 12, center.dy + 32, center.dx - 4, center.dy + 46), wrapPaint);
          canvas.drawRect(Rect.fromLTRB(center.dx + 4, center.dy + 32, center.dx + 12, center.dy + 46), wrapPaint);
          canvas.drawLine(Offset(center.dx - 12, center.dy + 35), Offset(center.dx - 4, center.dy + 39), tiePaint);
          canvas.drawLine(Offset(center.dx - 12, center.dy + 41), Offset(center.dx - 4, center.dy + 45), tiePaint);
          canvas.drawLine(Offset(center.dx + 4, center.dy + 35), Offset(center.dx + 12, center.dy + 39), tiePaint);
          canvas.drawLine(Offset(center.dx + 4, center.dy + 41), Offset(center.dx + 12, center.dy + 45), tiePaint);
        } else if (pantsId == 'paladin_greaves') {
          // Kutsal zırhlı bacaklıklar (Altın kaplama)
          final goldArmor = Paint()..color = Colors.amber..style = PaintingStyle.fill;
          final goldCross = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.2;
          canvas.drawCircle(Offset(center.dx - 8, center.dy + 28), 4.5, goldArmor);
          canvas.drawCircle(Offset(center.dx + 8, center.dy + 28), 4.5, goldArmor);
          canvas.drawLine(Offset(center.dx - 8, center.dy + 26), Offset(center.dx - 8, center.dy + 30), goldCross);
          canvas.drawLine(Offset(center.dx - 10, center.dy + 28), Offset(center.dx - 6, center.dy + 28), goldCross);
          canvas.drawLine(Offset(center.dx + 8, center.dy + 26), Offset(center.dx + 8, center.dy + 30), goldCross);
          canvas.drawLine(Offset(center.dx + 6, center.dy + 28), Offset(center.dx + 10, center.dy + 28), goldCross);
        } else if (pantsId == 'cyber_pants') {
          // Neon siber çizgiler & Dizlikler
          final neonPaint = Paint()..color = Colors.cyanAccent..style = PaintingStyle.stroke..strokeWidth = 1.5;
          canvas.drawLine(Offset(center.dx - 8, center.dy + 15), Offset(center.dx - 8, center.dy + 45), neonPaint);
          canvas.drawLine(Offset(center.dx + 8, center.dy + 15), Offset(center.dx + 8, center.dy + 45), neonPaint);
          final nodePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(center.dx - 8, center.dy + 28), 2.5, nodePaint);
          canvas.drawCircle(Offset(center.dx + 8, center.dy + 28), 2.5, nodePaint);
        }
      }
    } else {
      // Temel gri şort (Kıyafet kuşanılmamışsa)
      final defaultShortsPaint = Paint()..color = Colors.blueGrey.shade800..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTRB(center.dx - 13, center.dy + 11, center.dx + 13, center.dy + 24), defaultShortsPaint);
    }

    // Ayakkabı / RPG Bot Çizimi (Geliştirilmiş zemin tabanı & bot yakası)
    final bootPaint = Paint()
      ..color = Colors.brown.shade900
      ..style = PaintingStyle.fill;
    final solePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    // Sol Bot
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(center.dx - 14, center.dy + 44, center.dx - 2, center.dy + 50),
      const Radius.circular(3),
    ), bootPaint);
    canvas.drawRect(Rect.fromLTRB(center.dx - 14, center.dy + 49, center.dx - 2, center.dy + 51), solePaint);
    // Sağ Bot
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(center.dx + 2, center.dy + 44, center.dx + 14, center.dy + 50),
      const Radius.circular(3),
    ), bootPaint);
    canvas.drawRect(Rect.fromLTRB(center.dx + 2, center.dy + 49, center.dx + 14, center.dy + 51), solePaint);

    // --- 2. GÖVDE & KOLLAR (Nefes alma animasyonu ile dikey esner) ---
    final torsoItem = LootPool.getItemById(equippedItems['torso'] ?? '');
    final Color torsoColor = torsoItem?.color ?? Colors.grey.shade800;
    final String torsoId = torsoItem?.id ?? '';

    final double torsoTop = center.dy - 25 + breath;
    final double torsoBottom = center.dy + 14 + breath;

    // Kollar (Ten)
    final leftArmPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(center.dx - 22, torsoTop + 5, center.dx - 14, torsoBottom - 1),
        const Radius.circular(4),
      ));
    final rightArmPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(center.dx + 14, torsoTop + 5, center.dx + 22, torsoBottom - 1),
        const Radius.circular(4),
      ));
    canvas.drawPath(leftArmPath, skinPaint);
    canvas.drawPath(rightArmPath, skinPaint);

    // Eller (RPG Detayı)
    canvas.drawCircle(Offset(center.dx - 18, torsoBottom), 3.5, skinPaint);
    canvas.drawCircle(Offset(center.dx + 18, torsoBottom), 3.5, skinPaint);

    // Gövde (Ten)
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(center.dx - 14, torsoTop, center.dx + 14, torsoBottom),
      const Radius.circular(6),
    ), skinPaint);

    // Kıyafet Çizimi (Tamamen opak ve kol hatlarına kavisle oturan zırh/kıyafet)
    final torsoPaint = Paint()
      ..color = torsoColor.withValues(alpha: 1.0)
      ..style = PaintingStyle.fill;

    if (torsoId.isNotEmpty) {
      if (torsoId == 'tshirt') {
        // Düz Tişört: Opak kumaş, omuz kıvrımına oturan kollar ve ribana yaka
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 14.5, torsoTop, center.dx + 14.5, torsoBottom),
          const Radius.circular(5),
        ), torsoPaint);
        // Sol kol (Omuz kavisini tam takip eder, sivri köşesiz)
        canvas.drawRRect(RRect.fromRectAndCorners(
          Rect.fromLTRB(center.dx - 22, torsoTop + 5, center.dx - 14, torsoTop + 15),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        ), torsoPaint);
        // Sağ kol
        canvas.drawRRect(RRect.fromRectAndCorners(
          Rect.fromLTRB(center.dx + 14, torsoTop + 5, center.dx + 22, torsoTop + 15),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        ), torsoPaint);
        // Kol manşet dikiş çizgileri
        final hemPaint = Paint()..color = Colors.black12..style = PaintingStyle.stroke..strokeWidth = 1.0;
        canvas.drawLine(Offset(center.dx - 22, torsoTop + 15), Offset(center.dx - 14, torsoTop + 15), hemPaint);
        canvas.drawLine(Offset(center.dx + 14, torsoTop + 15), Offset(center.dx + 22, torsoTop + 15), hemPaint);
        // Ribana Yuvarlak Yaka (Şık bisiklet yaka)
        final collarFill = Paint()..color = const Color(0xFFE2E8F0)..style = PaintingStyle.fill;
        final collarLine = Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 1.2;
        canvas.drawOval(Rect.fromLTRB(center.dx - 5.5, torsoTop - 1, center.dx + 5.5, torsoTop + 5), collarFill);
        canvas.drawArc(Rect.fromLTRB(center.dx - 5.5, torsoTop - 1, center.dx + 5.5, torsoTop + 5), 0, pi, false, collarLine);
        // Göğüs amblemi / logosu
        final logoPaint = Paint()..color = Colors.indigo.shade400..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(center.dx - 9, torsoTop + 7, 4.5, 4.5), const Radius.circular(1.5)), logoPaint);
      } else if (torsoId == 'tunic') {
        // Tunik: Kavisli omuz kolları, otantik V bağcık ve deri kemer
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 15, torsoTop, center.dx + 15, torsoBottom + 5),
          const Radius.circular(4),
        ), torsoPaint);
        // Sol kol
        canvas.drawRRect(RRect.fromRectAndCorners(
          Rect.fromLTRB(center.dx - 22, torsoTop + 5, center.dx - 14, torsoTop + 16),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        ), torsoPaint);
        // Sağ kol
        canvas.drawRRect(RRect.fromRectAndCorners(
          Rect.fromLTRB(center.dx + 14, torsoTop + 5, center.dx + 22, torsoTop + 16),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        ), torsoPaint);
        // V yaka ve bağcıklar
        final lacePaint = Paint()..color = Colors.brown.shade900..style = PaintingStyle.stroke..strokeWidth = 1.3;
        canvas.drawLine(Offset(center.dx - 3, torsoTop), Offset(center.dx, torsoTop + 6), lacePaint);
        canvas.drawLine(Offset(center.dx + 3, torsoTop), Offset(center.dx, torsoTop + 6), lacePaint);
        canvas.drawLine(Offset(center.dx - 2, torsoTop + 3), Offset(center.dx + 2, torsoTop + 3), lacePaint);
        // Geniş deri kemer ve altın toka
        final beltPaint = Paint()..color = Colors.brown.shade900..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTRB(center.dx - 15, torsoBottom - 5, center.dx + 15, torsoBottom), beltPaint);
        final buckle = Paint()..color = Colors.amber..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(center.dx - 3, torsoBottom - 6, center.dx + 3, torsoBottom + 1), const Radius.circular(1)), buckle);
      } else if (torsoId == 'hoodie') {
        // Hoodie: Kanguru cep, kapüşon ipleri ve uzun kollar
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 16, torsoTop - 2, center.dx + 16, torsoBottom),
          const Radius.circular(6),
        ), torsoPaint);
        // Uzun kollar
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 22, torsoTop + 3, center.dx - 14, torsoBottom - 2),
          const Radius.circular(3),
        ), torsoPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx + 14, torsoTop + 3, center.dx + 22, torsoBottom - 2),
          const Radius.circular(3),
        ), torsoPaint);
        // Kanguru cebi
        final pouchPaint = Paint()..color = torsoColor.withValues(alpha: 0.8)..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 10, torsoBottom - 9, center.dx + 10, torsoBottom - 1),
          const Radius.circular(3),
        ), pouchPaint);
        // Kapüşon kordonları (Beyaz ipler)
        final cordPaint = Paint()..color = Colors.white70..style = PaintingStyle.stroke..strokeWidth = 1.2;
        canvas.drawLine(Offset(center.dx - 4, torsoTop + 2), Offset(center.dx - 4, torsoTop + 11), cordPaint);
        canvas.drawLine(Offset(center.dx + 4, torsoTop + 2), Offset(center.dx + 4, torsoTop + 11), cordPaint);
      } else if (torsoId == 'leather_armor') {
        // Deri Zırh: Çapraz tokalı kayışlar, omuzluklar ve pirinç perçinler
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 15, torsoTop - 1, center.dx + 15, torsoBottom),
          const Radius.circular(5),
        ), torsoPaint);
        // Omuzluklar
        final pauldron = Paint()..color = Colors.brown.shade800..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(center.dx - 17, torsoTop + 5), 4.5, pauldron);
        canvas.drawCircle(Offset(center.dx + 17, torsoTop + 5), 4.5, pauldron);
        // Çapraz deri kayışlar
        final strapPaint = Paint()..color = Colors.brown.shade900..style = PaintingStyle.stroke..strokeWidth = 2.2;
        canvas.drawLine(Offset(center.dx - 14, torsoTop + 3), Offset(center.dx + 14, torsoTop + 14), strapPaint);
        canvas.drawLine(Offset(center.dx + 14, torsoTop + 3), Offset(center.dx - 14, torsoTop + 14), strapPaint);
        // Pirinç göbek halkası
        final ringPaint = Paint()..color = Colors.amber.shade700..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(center.dx, torsoTop + 8.5), 2.5, ringPaint);
      } else if (torsoId == 'suit_jacket') {
        // Takım Elbise Ceketi: Yaka klapaları, beyaz gömlek, kırmızı kravat ve mendil
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 16, torsoTop - 1, center.dx + 16, torsoBottom),
          const Radius.circular(5),
        ), torsoPaint);
        // Kollar (Omuz kavisi ile uyumlu)
        canvas.drawRRect(RRect.fromRectAndCorners(
          Rect.fromLTRB(center.dx - 22, torsoTop + 4, center.dx - 14, torsoBottom - 2),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        ), torsoPaint);
        canvas.drawRRect(RRect.fromRectAndCorners(
          Rect.fromLTRB(center.dx + 14, torsoTop + 4, center.dx + 22, torsoBottom - 2),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        ), torsoPaint);
        // Beyaz gömlek V-neck
        final shirtPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
        final shirtPath = Path()
          ..moveTo(center.dx - 6, torsoTop - 1)
          ..lineTo(center.dx + 6, torsoTop - 1)
          ..lineTo(center.dx, torsoTop + 10)
          ..close();
        canvas.drawPath(shirtPath, shirtPaint);
        // Kırmızı kravat
        final tiePaint = Paint()..color = Colors.red.shade800..style = PaintingStyle.fill;
        final tiePath = Path()
          ..moveTo(center.dx - 1.5, torsoTop + 1)
          ..lineTo(center.dx + 1.5, torsoTop + 1)
          ..lineTo(center.dx + 2.5, torsoTop + 11)
          ..lineTo(center.dx, torsoTop + 14)
          ..lineTo(center.dx - 2.5, torsoTop + 11)
          ..close();
        canvas.drawPath(tiePath, tiePaint);
        // Ceket düğmesi
        canvas.drawCircle(Offset(center.dx, torsoBottom - 2), 1.5, Paint()..color = Colors.amber);
      } else if (torsoId == 'steel_chestplate') {
        // Çelik Zırh: Ağır şövalye göğüslüğü, omuzluklar ve kabartmalı metalik hatlar
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 16, torsoTop - 2, center.dx + 16, torsoBottom + 1),
          const Radius.circular(6),
        ), torsoPaint);
        // Omuz zırhları
        final pauldronPaint = Paint()..color = Colors.blueGrey.shade300..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(center.dx - 22, torsoTop + 2, center.dx - 14, torsoTop + 10), const Radius.circular(3)), pauldronPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(center.dx + 14, torsoTop + 2, center.dx + 22, torsoTop + 10), const Radius.circular(3)), pauldronPaint);
        // Metalik parıltı & Göğüs levhası
        final metalSheen = Paint()..color = Colors.white70..style = PaintingStyle.stroke..strokeWidth = 1.2;
        canvas.drawLine(Offset(center.dx, torsoTop + 2), Offset(center.dx, torsoBottom - 2), metalSheen);
        canvas.drawArc(Rect.fromLTRB(center.dx - 11, torsoTop + 3, center.dx - 1, torsoTop + 13), 0, pi, false, metalSheen);
        canvas.drawArc(Rect.fromLTRB(center.dx + 1, torsoTop + 3, center.dx + 11, torsoTop + 13), 0, pi, false, metalSheen);
      } else if (torsoId == 'mage_robe') {
        // Büyücü Cübbesi: Altın yaldızlı kenarlar, dökümlü zarif kollar ve geniş etek
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 16, torsoTop - 2, center.dx + 16, torsoBottom + 12),
          const Radius.circular(5),
        ), torsoPaint);
        // Dökümlü zarif kollar (Omuz kavisine ve kola oturan yuvarlak hatlı yapı)
        canvas.drawRRect(RRect.fromRectAndCorners(
          Rect.fromLTRB(center.dx - 22, torsoTop + 4, center.dx - 14, torsoBottom - 1),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        ), torsoPaint);
        canvas.drawRRect(RRect.fromRectAndCorners(
          Rect.fromLTRB(center.dx + 14, torsoTop + 4, center.dx + 22, torsoBottom - 1),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        ), torsoPaint);
        // Kol manşetlerinde altın süslemeler
        final cuffGold = Paint()..color = Colors.amberAccent..style = PaintingStyle.stroke..strokeWidth = 1.3;
        canvas.drawLine(Offset(center.dx - 22, torsoBottom - 2), Offset(center.dx - 14, torsoBottom - 2), cuffGold);
        canvas.drawLine(Offset(center.dx + 14, torsoBottom - 2), Offset(center.dx + 22, torsoBottom - 2), cuffGold);
        // Altın detaylar / Kenarlıklar
        final goldDetail = Paint()..color = Colors.amberAccent..style = PaintingStyle.stroke..strokeWidth = 1.5;
        canvas.drawLine(Offset(center.dx, torsoTop - 2), Offset(center.dx, torsoBottom + 12), goldDetail);
        canvas.drawRect(Rect.fromLTRB(center.dx - 16, torsoBottom + 10, center.dx + 16, torsoBottom + 12), Paint()..color = Colors.amberAccent);
        // Büyü taşı / Madalyon
        final gemPaint = Paint()..color = Colors.purpleAccent..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(center.dx, torsoTop + 5), 3, gemPaint);
      } else if (torsoId == 'assassin_cloak') {
        // Suikastçı Pelerini: Katmanlı pelerin yakası, omuzluklar ve kırmızı astar
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 17, torsoTop - 3, center.dx + 17, torsoBottom + 8),
          const Radius.circular(6),
        ), torsoPaint);
        // Omuz korumalıkları & Pelerin broşu
        final padPaint = Paint()..color = Colors.black87..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(center.dx - 19, torsoTop - 2, center.dx - 10, torsoTop + 4), const Radius.circular(2)), padPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(center.dx + 10, torsoTop - 2, center.dx + 19, torsoTop + 4), const Radius.circular(2)), padPaint);
        // Gümüş broş / Amblem
        canvas.drawCircle(Offset(center.dx, torsoTop + 4), 2.5, Paint()..color = Colors.white70);
      } else if (torsoId == 'paladin_armor') {
        // Kutsal Işık Zırhı: Parlak altın işlemeler ve göğüste parlayan haç mücevheri
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 16, torsoTop - 3, center.dx + 16, torsoBottom + 2),
          const Radius.circular(6),
        ), torsoPaint);
        // Altın kenar bordürleri
        final goldBorder = Paint()..color = Colors.amber..style = PaintingStyle.stroke..strokeWidth = 1.5;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(center.dx - 15, torsoTop - 2, center.dx + 15, torsoBottom + 1), const Radius.circular(5)), goldBorder);
        // Parlayan kutsal mücevher
        final gemPaint = Paint()..color = Colors.cyanAccent..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(center.dx, torsoTop + 7), 4.5, gemPaint);
        final glowCore = Paint()..color = Colors.white..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(center.dx, torsoTop + 7), 2, glowCore);
      } else if (torsoId == 'cyber_suit') {
        // Siber Zırh: Göğüs reaktörü ve neon devre hatları
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 16, torsoTop - 2, center.dx + 16, torsoBottom),
          const Radius.circular(5),
        ), torsoPaint);
        // Neon devre çizgileri
        final gridPaint = Paint()..color = Colors.cyanAccent..style = PaintingStyle.stroke..strokeWidth = 1.3;
        canvas.drawLine(Offset(center.dx - 12, torsoTop + 6), Offset(center.dx + 12, torsoTop + 6), gridPaint);
        canvas.drawLine(Offset(center.dx - 8, torsoTop + 12), Offset(center.dx + 8, torsoTop + 12), gridPaint);
        // Siber çekirdek
        final corePaint = Paint()..color = Colors.cyanAccent..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(center.dx, torsoTop + 6), 3.5, corePaint);
        canvas.drawCircle(Offset(center.dx, torsoTop + 6), 1.5, Paint()..color = Colors.white);
      }
    } else {
      // Temel tişört (Giysi kuşanılmamışsa)
      final defaultTshirtPaint = Paint()..color = Colors.grey.shade700..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(center.dx - 14, torsoTop, center.dx + 14, torsoBottom),
        const Radius.circular(5),
      ), defaultTshirtPaint);
      final collar = Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 1.2;
      canvas.drawArc(Rect.fromLTRB(center.dx - 4, torsoTop, center.dx + 4, torsoTop + 4), 0, pi, false, collar);
    }

    // --- 3. BOYUN & KAFA (Ten, boyun ve kafa dikey nefes alma ile senkron) ---
    final double headY = center.dy - 43 + breath;
    final double neckTop = center.dy - 30 + breath;

    // Boyun
    canvas.drawRect(Rect.fromLTRB(center.dx - 4, neckTop, center.dx + 4, torsoTop + 1), skinPaint);

    // Kafa
    canvas.drawCircle(Offset(center.dx, headY), 16, skinPaint);

    // --- 4. ŞAPKA & SAÇ (Şapkalar kafaya tam oturacak şekilde aşağı hizalıdır) ---
    final hatItem = LootPool.getItemById(equippedItems['hat'] ?? '');
    final Color hatColor = hatItem?.color ?? Colors.transparent;
    final String hatId = hatItem?.id ?? '';

    // Saç Çizimi:
    // Demir miğfer ve tam ninja maskesi hariç tüm şapkalarda saç çizilir.
    // Bandana ve taç kafanın üstünü açık bıraktığı için tam saç kubbesi çizilir (böylece kel kalmaz!).
    final bool showHair = hatId != 'iron_helmet' && hatId != 'ninja_mask';
    final hairPaint = Paint()..color = Colors.brown.shade900..style = PaintingStyle.fill;

    if (showHair) {
      final bool needsFullTopHair = hatId.isEmpty || hatId == 'bandana' || hatId == 'crown';

      if (needsFullTopHair) {
        // Tam saç kubbesi (Kafanın üstünü gür saçlarla kaplar)
        canvas.drawArc(
          Rect.fromLTRB(center.dx - 17, headY - 17, center.dx + 17, headY - 5),
          pi, pi, true, hairPaint
        );
        // Ön kaküller
        final hairPath = Path()
          ..moveTo(center.dx - 16, headY - 10)
          ..lineTo(center.dx - 10, headY - 10)
          ..lineTo(center.dx - 11, headY - 4) // kakül 1
          ..lineTo(center.dx - 4, headY - 11)
          ..lineTo(center.dx - 1, headY - 3)  // kakül 2 (orta)
          ..lineTo(center.dx + 4, headY - 11)
          ..lineTo(center.dx + 11, headY - 4) // kakül 3
          ..lineTo(center.dx + 10, headY - 10)
          ..lineTo(center.dx + 16, headY - 10)
          ..close();
        canvas.drawPath(hairPath, hairPaint);
      } else {
        // Şapka takılıyken: Şapkanın altından ve yanlarından çıkan şık saç tutamları
        final sideHairPath = Path()
          // Sol favori / yan saç
          ..moveTo(center.dx - 16, headY - 6)
          ..lineTo(center.dx - 13, headY - 6)
          ..lineTo(center.dx - 14, headY + 3)
          ..lineTo(center.dx - 17, headY - 1)
          ..close()
          // Sağ favori / yan saç
          ..moveTo(center.dx + 13, headY - 6)
          ..lineTo(center.dx + 16, headY - 6)
          ..lineTo(center.dx + 17, headY - 1)
          ..lineTo(center.dx + 14, headY + 3)
          ..close()
          // Alın saç tutamı
          ..moveTo(center.dx - 5, headY - 6)
          ..lineTo(center.dx + 2, headY - 6)
          ..lineTo(center.dx - 2, headY - 2.5)
          ..close();
        canvas.drawPath(sideHairPath, hairPaint);
      }
    }

    // Gözler (Demir miğfer veya ninja maskesi hariç normal çizim)
    if (hatId != 'iron_helmet' && hatId != 'ninja_mask') {
      canvas.drawCircle(Offset(center.dx - 5, headY - 1), 3.2, eyePaint);
      canvas.drawCircle(Offset(center.dx + 5, headY - 1), 3.2, eyePaint);
      
      final eyeReflectionPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(center.dx - 6.2, headY - 2.2), 0.9, eyeReflectionPaint);
      canvas.drawCircle(Offset(center.dx + 3.8, headY - 2.2), 0.9, eyeReflectionPaint);

      // Gülümseyen Ağız
      final mouthPaint = Paint()
        ..color = Colors.red.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromLTRB(center.dx - 3, headY + 3, center.dx + 3, headY + 7),
        0, pi, false, mouthPaint
      );

      // Yanak allığı
      final blushPaint = Paint()..color = Colors.pinkAccent.withValues(alpha: 0.35)..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(center.dx - 9, headY + 3), 2.5, blushPaint);
      canvas.drawCircle(Offset(center.dx + 9, headY + 3), 2.5, blushPaint);
    }

    // Şapkaların Çizimi (Orijinal zengin çizim tarzı korunmuş, yüksekliği ve tombikliği hafifçe dengelenmiş tasarımlar)
    if (hatId.isNotEmpty) {
      final hatPaint = Paint()..color = hatColor..style = PaintingStyle.fill;

      if (hatId == 'straw_hat') {
        // Hasır Şapka: Orijinal yuvarlak kubbe formu korunarak hafifçe kısaltıldı ve gözler tamamen açıkta
        final domePath = Path()
          ..moveTo(center.dx - 13, headY - 8)
          ..lineTo(center.dx - 13, headY - 12)
          ..arcToPoint(
            Offset(center.dx + 13, headY - 12),
            radius: const Radius.elliptical(13, 10.5),
            clockwise: true,
          )
          ..lineTo(center.dx + 13, headY - 8)
          ..close();
        canvas.drawPath(domePath, hatPaint);
        // Kırmızı şapka kurdelesi
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 13.5, headY - 11, center.dx + 13.5, headY - 7.5),
          const Radius.circular(1),
        ), Paint()..color = Colors.red.shade800);
        // Geniş kenarlık (Gözlerin hemen üstünde kalarak gözleri engellemez)
        canvas.drawOval(
          Rect.fromLTRB(center.dx - 25, headY - 11, center.dx + 25, headY - 5),
          hatPaint,
        );
        // Hasır kenarlık çizgisi
        final rimEdge = Paint()..color = Colors.brown.shade400..style = PaintingStyle.stroke..strokeWidth = 0.8;
        canvas.drawOval(
          Rect.fromLTRB(center.dx - 25, headY - 11, center.dx + 25, headY - 5),
          rimEdge,
        );
      } else if (hatId == 'bandana') {
        // Bandana: Saçların ve alnın üstünden geçen kırmızı bandana
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 16.5, headY - 11, center.dx + 16.5, headY - 4),
          const Radius.circular(2),
        ), hatPaint);
        // Bandana düğümü ve arkadan sarkan kumaş uçları
        canvas.drawCircle(Offset(center.dx - 17, headY - 7), 3.5, hatPaint);
        final tailPath = Path()
          ..moveTo(center.dx - 17, headY - 7)
          ..lineTo(center.dx - 23, headY + 1)
          ..lineTo(center.dx - 19, headY + 6)
          ..lineTo(center.dx - 15, headY - 5)
          ..close();
        canvas.drawPath(tailPath, hatPaint);
      } else if (hatId == 'cap') {
        // Spor Kep: Orijinal zengin kubbe ve sağa kıvrık siperlik, hafifçe kısaltılmış ve fit
        final capDome = Path()
          ..moveTo(center.dx - 15, headY - 5)
          ..lineTo(center.dx - 15, headY - 9)
          ..arcToPoint(
            Offset(center.dx + 15, headY - 9),
            radius: const Radius.elliptical(15, 12),
            clockwise: true,
          )
          ..lineTo(center.dx + 15, headY - 5)
          ..close();
        canvas.drawPath(capDome, hatPaint);
        // Kep alt bandı
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 15, headY - 8, center.dx + 15, headY - 4.5),
          const Radius.circular(1.5),
        ), hatPaint);
        // Sağa doğru kıvrık şık siperlik
        final visorPath = Path()
          ..moveTo(center.dx + 2, headY - 7)
          ..lineTo(center.dx + 23, headY - 4.5)
          ..lineTo(center.dx + 21, headY - 1.5)
          ..lineTo(center.dx + 10, headY - 3.5)
          ..close();
        canvas.drawPath(visorPath, hatPaint);
        // Tepedeki kep düğmesi
        canvas.drawCircle(Offset(center.dx, headY - 20.5), 2.2, Paint()..color = Colors.white70);
      } else if (hatId == 'beanie') {
        // Kışlık Bere: Orijinal sevimli kubbe, manşet ve ponpon; yüksekliği hafifçe dengelendi
        final beanieDome = Path()
          ..moveTo(center.dx - 15, headY - 5)
          ..lineTo(center.dx - 15, headY - 9.5)
          ..arcToPoint(
            Offset(center.dx + 15, headY - 9.5),
            radius: const Radius.elliptical(15, 12),
            clockwise: true,
          )
          ..lineTo(center.dx + 15, headY - 5)
          ..close();
        canvas.drawPath(beanieDome, hatPaint);
        // Katlama manşeti
        final cuffPaint = Paint()..color = hatColor.withValues(alpha: 0.85)..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 15.5, headY - 9, center.dx + 15.5, headY - 4),
          const Radius.circular(3),
        ), cuffPaint);
        // Beyaz ponpon
        canvas.drawCircle(Offset(center.dx, headY - 21), 4.0, Paint()..color = Colors.white);
      } else if (hatId == 'cowboy_hat') {
        // Kovboy Şapkası: Orijinal tepe ve kıvrımlı kenarlık, dengeli yükseklik
        final crownPath = Path()
          ..moveTo(center.dx - 13.5, headY - 7)
          ..lineTo(center.dx - 12.5, headY - 17)
          ..quadraticBezierTo(center.dx, headY - 14.5, center.dx + 12.5, headY - 17)
          ..lineTo(center.dx + 13.5, headY - 7)
          ..close();
        canvas.drawPath(crownPath, hatPaint);
        // Şapka kemeri & Gümüş yıldız toka
        canvas.drawRect(Rect.fromLTRB(center.dx - 13.5, headY - 10, center.dx + 13.5, headY - 7), Paint()..color = Colors.brown.shade900);
        canvas.drawCircle(Offset(center.dx, headY - 8.5), 1.8, Paint()..color = Colors.amber);
        // Geniş kıvrımlı kenarlık
        final brimPath = Path()
          ..moveTo(center.dx - 25, headY - 11.5)
          ..quadraticBezierTo(center.dx - 15, headY - 5, center.dx, headY - 6)
          ..quadraticBezierTo(center.dx + 15, headY - 5, center.dx + 25, headY - 11.5)
          ..quadraticBezierTo(center.dx + 16, headY - 8, center.dx, headY - 9)
          ..quadraticBezierTo(center.dx - 16, headY - 8, center.dx - 25, headY - 11.5)
          ..close();
        canvas.drawPath(brimPath, hatPaint);
      } else if (hatId == 'iron_helmet') {
        // Demir Miğfer: Kafayı tamamen saran şövalye zırhı
        canvas.drawArc(
          Rect.fromLTRB(center.dx - 16.5, headY - 20, center.dx + 16.5, headY - 2),
          pi, pi, true, hatPaint
        );
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 16.5, headY - 4, center.dx + 16.5, headY + 8),
          const Radius.circular(4),
        ), hatPaint);
        canvas.drawRect(Rect.fromLTRB(center.dx - 2.5, headY - 6, center.dx + 2.5, headY + 7), hatPaint);
        final slitPaint = Paint()..color = Colors.black87..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTRB(center.dx - 12, headY - 2.5, center.dx - 3, headY + 1), slitPaint);
        canvas.drawRect(Rect.fromLTRB(center.dx + 3, headY - 2.5, center.dx + 12, headY + 1), slitPaint);
        final helmetEye = Paint()..color = Colors.cyanAccent..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(center.dx - 7, headY - 0.7), 1.3, helmetEye);
        canvas.drawCircle(Offset(center.dx + 7, headY - 0.7), 1.3, helmetEye);
        final crestPaint = Paint()..color = Colors.red.shade700..style = PaintingStyle.fill;
        final crestPath = Path()
          ..moveTo(center.dx - 2, headY - 20)
          ..lineTo(center.dx + 2, headY - 20)
          ..lineTo(center.dx + 3, headY - 27)
          ..lineTo(center.dx - 3, headY - 27)
          ..close();
        canvas.drawPath(crestPath, crestPaint);
      } else if (hatId == 'mage_hat') {
        // Büyücü Şapkası: Zarif külah ve gözleri açan geniş siperlik
        final conePath = Path()
          ..moveTo(center.dx - 11, headY - 8)
          ..lineTo(center.dx + 11, headY - 8)
          ..quadraticBezierTo(center.dx + 5, headY - 20, center.dx + 14, headY - 30)
          ..quadraticBezierTo(center.dx + 3, headY - 22, center.dx - 11, headY - 8)
          ..close();
        canvas.drawPath(conePath, hatPaint);
        canvas.drawOval(
          Rect.fromLTRB(center.dx - 22, headY - 11, center.dx + 22, headY - 6.5),
          hatPaint,
        );
        canvas.drawRect(Rect.fromLTRB(center.dx - 11, headY - 8.5, center.dx + 11, headY - 6.5), Paint()..color = Colors.amber);
        canvas.drawCircle(Offset(center.dx, headY - 7.5), 1.8, Paint()..color = Colors.cyanAccent);
      } else if (hatId == 'ninja_mask') {
        // Ninja Maskesi: Kafayı ve yüzü saran siyah maske + Alın metal plakası
        canvas.drawCircle(Offset(center.dx, headY), 16, hatPaint);
        // Boyun örtüsü
        canvas.drawRect(Rect.fromLTRB(center.dx - 10, headY + 10, center.dx + 10, neckTop + 1), hatPaint);
        // Alın metal koruyucusu (Hitai-ate)
        final metalPlate = Paint()..color = Colors.blueGrey.shade200..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 10, headY - 11, center.dx + 10, headY - 5),
          const Radius.circular(2),
        ), metalPlate);
        // Göz yarık bölgesi (Ten rengi pencere)
        final eyeSlot = Paint()..color = const Color(0xFFFFD1A9)..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 11, headY - 3.5, center.dx + 11, headY + 2.5),
          const Radius.circular(2),
        ), eyeSlot);
        // Odaklanmış keskin ninja gözleri
        canvas.drawCircle(Offset(center.dx - 5, headY - 0.5), 1.8, eyePaint);
        canvas.drawCircle(Offset(center.dx + 5, headY - 0.5), 1.8, eyePaint);
      } else if (hatId == 'crown') {
        // Altın Kral Tacı: Alnın üstüne tam oturan 5 uçlu görkemli taç
        // Taç taban halkası (Alın hizasında)
        final crownBase = Path()
          ..moveTo(center.dx - 15, headY - 7)
          ..lineTo(center.dx + 15, headY - 7)
          ..lineTo(center.dx + 16.5, headY - 22) // Sağ dış uç
          ..lineTo(center.dx + 9, headY - 14)
          ..lineTo(center.dx + 7, headY - 26)    // Sağ orta uç
          ..lineTo(center.dx, headY - 15)
          ..lineTo(center.dx, headY - 28)         // En yüksek merkez uç
          ..lineTo(center.dx, headY - 15)
          ..lineTo(center.dx - 7, headY - 26)    // Sol orta uç
          ..lineTo(center.dx - 9, headY - 14)
          ..lineTo(center.dx - 16.5, headY - 22) // Sol dış uç
          ..close();
        canvas.drawPath(crownBase, hatPaint);
        // Taç zemin bandı
        final bandPaint = Paint()..color = Colors.amber.shade700..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 15, headY - 7.5, center.dx + 15, headY - 4.5),
          const Radius.circular(1.5),
        ), bandPaint);
        // Parlayan değerli yakut ve zümrüt taşlar
        canvas.drawCircle(Offset(center.dx, headY - 26), 2.2, Paint()..color = Colors.redAccent);
        canvas.drawCircle(Offset(center.dx - 7, headY - 24), 1.8, Paint()..color = Colors.blueAccent);
        canvas.drawCircle(Offset(center.dx + 7, headY - 24), 1.8, Paint()..color = Colors.greenAccent);
        canvas.drawCircle(Offset(center.dx - 15, headY - 20), 1.5, Paint()..color = Colors.purpleAccent);
        canvas.drawCircle(Offset(center.dx + 15, headY - 20), 1.5, Paint()..color = Colors.purpleAccent);
      } else if (hatId == 'cyber_visor') {
        // Siber Vizör: Gözleri saran yüksek teknolojili visor ve neon HUD
        final visorPaint = Paint()..color = Colors.cyanAccent.withValues(alpha: 0.9)..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 14, headY - 4, center.dx + 14, headY + 2.5),
          const Radius.circular(3),
        ), visorPaint);
        // Kafa arkası sabitleme kordonu
        final strapPaint = Paint()..color = Colors.black87..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTRB(center.dx - 16.5, headY - 2, center.dx - 13, headY + 1), strapPaint);
        canvas.drawRect(Rect.fromLTRB(center.dx + 13, headY - 2, center.dx + 16.5, headY + 1), strapPaint);
        // Parlayan beyaz neon lazer çizgisi
        final glowPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawLine(Offset(center.dx - 13, headY - 0.5), Offset(center.dx + 13, headY - 0.5), glowPaint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CharacterPainter oldDelegate) {
    return oldDelegate.equippedItems != equippedItems ||
        oldDelegate.animationValue != animationValue;
  }
}

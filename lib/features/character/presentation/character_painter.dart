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
    final String rawPantsId = equippedItems['pants'] ?? '';
    final String resolvedPantsId = (rawPantsId == 'leather_greaves') ? 'baggy_pants' : rawPantsId;
    final pantsItem = LootPool.getItemById(resolvedPantsId);
    final Color pantsColor = pantsItem?.color ?? (resolvedPantsId == 'baggy_pants' ? const Color(0xFF1E3A8A) : Colors.grey.shade700);
    final String pantsId = pantsItem?.id ?? resolvedPantsId;

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
      } else if (pantsId == 'baggy_pants' || pantsId == 'leather_greaves') {
        // Baggy Pantolon: Geniş paçalı, sokak modasına uygun dökümlü koyu mavi/indigo denim pantolon
        final denimBase = Paint()..color = const Color(0xFF1B2B4C)..style = PaintingStyle.fill; // Koyu indigo kot kumaşı
        final denimDark = Paint()..color = const Color(0xFF101A2E)..style = PaintingStyle.fill;
        final denimWash = Paint()..color = const Color(0x3560A5FA)..style = PaintingStyle.fill; // Vintage taşlama aydınlatması
        final foldShadow = Paint()..color = Colors.black.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 1.2;
        final foldLight = Paint()..color = Colors.white.withValues(alpha: 0.20)..style = PaintingStyle.stroke..strokeWidth = 1.0;

        // 1. Sol Paça (Geniş, dökümlü ve ayakkabıya binen baggy kesim)
        final leftBaggy = Path()
          ..moveTo(center.dx - 14.5, center.dy + 12)
          ..lineTo(center.dx - 1.5, center.dy + 12)
          ..lineTo(center.dx - 1.5, center.dy + 21) // Rahat düşük ağ (relaxed drop crotch)
          ..lineTo(center.dx - 2.0, center.dy + 48) // Dökümlü iç paça
          ..lineTo(center.dx - 15.0, center.dy + 48) // Ayakkabıya oturan geniş dış paça
          ..lineTo(center.dx - 16.0, center.dy + 34) // Diz bollaşması
          ..lineTo(center.dx - 14.5, center.dy + 18)
          ..close();
        canvas.drawPath(leftBaggy, denimBase);

        // 2. Sağ Paça (Geniş, dökümlü ve ayakkabıya binen baggy kesim)
        final rightBaggy = Path()
          ..moveTo(center.dx + 1.5, center.dy + 12)
          ..lineTo(center.dx + 14.5, center.dy + 12)
          ..lineTo(center.dx + 14.5, center.dy + 18)
          ..lineTo(center.dx + 16.0, center.dy + 34) // Diz bollaşması
          ..lineTo(center.dx + 15.0, center.dy + 48) // Geniş dış paça
          ..lineTo(center.dx + 2.0, center.dy + 48)
          ..lineTo(center.dx + 1.5, center.dy + 21)
          ..close();
        canvas.drawPath(rightBaggy, denimBase);

        // Ağ gölgesi
        final crotchShadow = Path()
          ..moveTo(center.dx - 2.0, center.dy + 20)
          ..lineTo(center.dx, center.dy + 23)
          ..lineTo(center.dx + 2.0, center.dy + 20)
          ..lineTo(center.dx, center.dy + 15)
          ..close();
        canvas.drawPath(crotchShadow, denimDark);

        // 3. Vintage Taşlama / Yıkama Efekti (Uyluk & Diz aydınlatması)
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 13.0, center.dy + 22, center.dx - 4.5, center.dy + 36),
          const Radius.circular(4),
        ), denimWash);
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx + 4.5, center.dy + 22, center.dx + 13.0, center.dy + 36),
          const Radius.circular(4),
        ), denimWash);

        // Kırışıklık bıyıkları (Whiskering efektleri - basen çizgileri)
        final whiskerPaint = Paint()..color = Colors.lightBlue.withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 1.0;
        canvas.drawLine(Offset(center.dx - 13.5, center.dy + 16), Offset(center.dx - 5.0, center.dy + 19), whiskerPaint);
        canvas.drawLine(Offset(center.dx - 13.0, center.dy + 19), Offset(center.dx - 6.0, center.dy + 22), whiskerPaint);
        canvas.drawLine(Offset(center.dx + 13.5, center.dy + 16), Offset(center.dx + 5.0, center.dy + 19), whiskerPaint);
        canvas.drawLine(Offset(center.dx + 13.0, center.dy + 19), Offset(center.dx + 6.0, center.dy + 22), whiskerPaint);

        // 4. Paça Yığılma Kıvrımları (Stacking Folds - Baggy paçaların bot üzerine dökümü)
        // Sol paça kıvrımları
        canvas.drawLine(Offset(center.dx - 15.5, center.dy + 41), Offset(center.dx - 3.0, center.dy + 43), foldShadow);
        canvas.drawLine(Offset(center.dx - 15.0, center.dy + 40.5), Offset(center.dx - 3.5, center.dy + 42.5), foldLight);
        canvas.drawLine(Offset(center.dx - 15.0, center.dy + 45.5), Offset(center.dx - 2.5, center.dy + 46.5), foldShadow);
        canvas.drawLine(Offset(center.dx - 14.5, center.dy + 45.0), Offset(center.dx - 3.0, center.dy + 46.0), foldLight);
        // Sağ paça kıvrımları
        canvas.drawLine(Offset(center.dx + 3.0, center.dy + 43), Offset(center.dx + 15.5, center.dy + 41), foldShadow);
        canvas.drawLine(Offset(center.dx + 3.5, center.dy + 42.5), Offset(center.dx + 15.0, center.dy + 40.5), foldLight);
        canvas.drawLine(Offset(center.dx + 2.5, center.dy + 46.5), Offset(center.dx + 15.0, center.dy + 45.5), foldShadow);
        canvas.drawLine(Offset(center.dx + 3.0, center.dy + 46.0), Offset(center.dx + 14.5, center.dy + 45.0), foldLight);

        // 5. Bel Kemeri & Kot Detayları
        final beltPaint = Paint()..color = const Color(0xFF1E2022)..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 14.5, center.dy + 11, center.dx + 14.5, center.dy + 15.5),
          const Radius.circular(2),
        ), beltPaint);
        // Gümüş metal kemer tokası
        final silverBuckle = Paint()..color = const Color(0xFFCFD8DC)..style = PaintingStyle.fill;
        final buckleInner = Paint()..color = const Color(0xFF263238)..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTRB(center.dx - 2.5, center.dy + 11.5, center.dx + 2.5, center.dy + 15.0), silverBuckle);
        canvas.drawRect(Rect.fromLTRB(center.dx - 1.2, center.dy + 12.3, center.dx + 1.2, center.dy + 14.2), buckleInner);
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
          // Kutsal Zırhlı Bacaklıklar: Parlak kutsal gümüş/çelik plaka, altın bezenmiş çerçeveler,
          // prizmatik diz koruyucuları (poleyns), mavi mana mücevheri ve kabartmalı altın haçlar
          final silverBase = Paint()..color = const Color(0xFFECEFF1)..style = PaintingStyle.fill;
          final silverShade = Paint()..color = const Color(0xFFCFD8DC)..style = PaintingStyle.fill;
          final royalBlue = Paint()..color = const Color(0xFF1A237E)..style = PaintingStyle.fill;
          final goldTrim = Paint()..color = const Color(0xFFFFB300)..style = PaintingStyle.fill;
          final goldLight = Paint()..color = const Color(0xFFFFD54F)..style = PaintingStyle.fill;
          final goldBorder = Paint()..color = const Color(0xFFFFB300)..style = PaintingStyle.stroke..strokeWidth = 1.2;
          final leatherStrap = Paint()..color = const Color(0xFF4E342E)..style = PaintingStyle.fill;

          // 1. Kutsal Kraliyet Alt Kumaşı (Uyluk kısmı safir kumaş kaplama)
          canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTRB(center.dx - 13, center.dy + 11, center.dx - 3, center.dy + 25),
            const Radius.circular(2),
          ), royalBlue);
          canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTRB(center.dx + 3, center.dy + 11, center.dx + 13, center.dy + 25),
            const Radius.circular(2),
          ), royalBlue);

          // 2. Alt Baldır Bağlama Deri Kayışları (Toka detaylarıyla)
          // Sol baldır kayışları
          canvas.drawRect(Rect.fromLTRB(center.dx - 13, center.dy + 31, center.dx - 3, center.dy + 33), leatherStrap);
          canvas.drawRect(Rect.fromLTRB(center.dx - 13, center.dy + 42, center.dx - 3, center.dy + 44), leatherStrap);
          // Sağ baldır kayışları
          canvas.drawRect(Rect.fromLTRB(center.dx + 3, center.dy + 31, center.dx + 13, center.dy + 33), leatherStrap);
          canvas.drawRect(Rect.fromLTRB(center.dx + 3, center.dy + 42, center.dx + 13, center.dy + 44), leatherStrap);
          // Altın minik tokalar
          canvas.drawRect(Rect.fromLTRB(center.dx - 13.5, center.dy + 31, center.dx - 11.5, center.dy + 33), goldLight);
          canvas.drawRect(Rect.fromLTRB(center.dx + 11.5, center.dy + 31, center.dx + 13.5, center.dy + 33), goldLight);

          // 3. Parlatılmış Kutsal Gümüş Zırh Plakaları (Shin Greaves)
          // Sol Plaka
          final leftGreaveRect = Rect.fromLTRB(center.dx - 12.5, center.dy + 24, center.dx - 3.5, center.dy + 46);
          canvas.drawRRect(RRect.fromRectAndRadius(leftGreaveRect, const Radius.circular(3)), silverBase);
          canvas.drawRect(Rect.fromLTRB(center.dx - 8.0, center.dy + 24, center.dx - 3.5, center.dy + 46), silverShade);
          canvas.drawRRect(RRect.fromRectAndRadius(leftGreaveRect, const Radius.circular(3)), goldBorder);

          // Sağ Plaka
          final rightGreaveRect = Rect.fromLTRB(center.dx + 3.5, center.dy + 24, center.dx + 12.5, center.dy + 46);
          canvas.drawRRect(RRect.fromRectAndRadius(rightGreaveRect, const Radius.circular(3)), silverBase);
          canvas.drawRect(Rect.fromLTRB(center.dx + 8.0, center.dy + 24, center.dx + 12.5, center.dy + 46), silverShade);
          canvas.drawRRect(RRect.fromRectAndRadius(rightGreaveRect, const Radius.circular(3)), goldBorder);

          // Merkezi dikey parlak altın omurga çizgisi
          final ridgePaint = Paint()..color = goldLight.color..style = PaintingStyle.stroke..strokeWidth = 1.0;
          canvas.drawLine(Offset(center.dx - 8, center.dy + 28), Offset(center.dx - 8, center.dy + 45), ridgePaint);
          canvas.drawLine(Offset(center.dx + 8, center.dy + 28), Offset(center.dx + 8, center.dy + 45), ridgePaint);

          // 4. Kabartmalı Kutsal Altın Haçlar (Shin Crosses)
          // Sol Haç
          canvas.drawRect(Rect.fromLTRB(center.dx - 9.0, center.dy + 34, center.dx - 7.0, center.dy + 43), goldTrim);
          canvas.drawRect(Rect.fromLTRB(center.dx - 11.2, center.dy + 36.5, center.dx - 4.8, center.dy + 38.5), goldTrim);
          canvas.drawRect(Rect.fromLTRB(center.dx - 8.5, center.dy + 34.5, center.dx - 7.5, center.dy + 42.5), goldLight);
          canvas.drawRect(Rect.fromLTRB(center.dx - 10.7, center.dy + 37, center.dx - 5.3, center.dy + 38), goldLight);

          // Sağ Haç
          canvas.drawRect(Rect.fromLTRB(center.dx + 7.0, center.dy + 34, center.dx + 9.0, center.dy + 43), goldTrim);
          canvas.drawRect(Rect.fromLTRB(center.dx + 4.8, center.dy + 36.5, center.dx + 11.2, center.dy + 38.5), goldTrim);
          canvas.drawRect(Rect.fromLTRB(center.dx + 7.5, center.dy + 34.5, center.dx + 8.5, center.dy + 42.5), goldLight);
          canvas.drawRect(Rect.fromLTRB(center.dx + 5.3, center.dy + 37, center.dx + 10.7, center.dy + 38), goldLight);

          // 5. 3D Elmas Diz Zırhı (Sculpted Diamond Poleyns) & Kutsal Mana Kristali
          void drawKneePoleyn(double kx) {
            final poleynPath = Path()
              ..moveTo(kx, center.dy + 20)
              ..lineTo(kx + 4.5, center.dy + 25)
              ..lineTo(kx, center.dy + 30)
              ..lineTo(kx - 4.5, center.dy + 25)
              ..close();
            canvas.drawPath(poleynPath, goldTrim);
            // Işık vuran üst kanat
            final topHalf = Path()
              ..moveTo(kx, center.dy + 20)
              ..lineTo(kx + 4.5, center.dy + 25)
              ..lineTo(kx - 4.5, center.dy + 25)
              ..close();
            canvas.drawPath(topHalf, goldLight);
            canvas.drawPath(poleynPath, Paint()..color = const Color(0xFFFFF176)..style = PaintingStyle.stroke..strokeWidth = 0.8);

            // Gömülü Parıldayan Kutsal Safir / Mana Taşı (Cyan Aura)
            canvas.drawCircle(Offset(kx, center.dy + 25), 3.0, Paint()..color = Colors.cyanAccent.withValues(alpha: 0.4));
            canvas.drawCircle(Offset(kx, center.dy + 25), 2.0, Paint()..color = const Color(0xFF00E5FF));
            canvas.drawCircle(Offset(kx - 0.5, center.dy + 24.5), 0.7, Paint()..color = Colors.white);
          }
          drawKneePoleyn(center.dx - 8);
          drawKneePoleyn(center.dx + 8);
        } else if (pantsId == 'cyber_pants') {
          // Siber Tayt / Dış İskelet (Nanoteknoloji karbon kompozit zırh, kinetik diz servoları,
          // 45 dereceli siber veri yolları ve aktif telemetri LED göstergeleri)
          final carbonDark = Paint()..color = const Color(0xFF1E272E)..style = PaintingStyle.fill;
          final carbonPlate = Paint()..color = const Color(0xFF2C3E50)..style = PaintingStyle.fill;
          final servoTitanium = Paint()..color = const Color(0xFF37474F)..style = PaintingStyle.fill;
          final neonCyan = Paint()..color = const Color(0xFF00E5FF)..style = PaintingStyle.fill;
          final neonLine = Paint()..color = const Color(0xFF18FFFF)..style = PaintingStyle.stroke..strokeWidth = 1.2;
          final neonGlow = Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)..style = PaintingStyle.fill;

          // 1. Karbon Nano Kompresyon Temeli (Siyah/Koyu grafit zırh kumaşı)
          canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTRB(center.dx - 13, center.dy + 11, center.dx - 3, center.dy + 47),
            const Radius.circular(3),
          ), carbonDark);
          canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTRB(center.dx + 3, center.dy + 11, center.dx + 13, center.dy + 47),
            const Radius.circular(3),
          ), carbonDark);
          canvas.drawRect(Rect.fromLTRB(center.dx - 13, center.dy + 11, center.dx + 13, center.dy + 18), carbonDark);

          // 2. Karbon Elyaf Kompozit Uyluk ve Baldır Koruma Plakaları
          // Sol Uyluk
          canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTRB(center.dx - 13.5, center.dy + 13.5, center.dx - 3.5, center.dy + 22),
            const Radius.circular(2),
          ), carbonPlate);
          // Sağ Uyluk
          canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTRB(center.dx + 3.5, center.dy + 13.5, center.dx + 13.5, center.dy + 22),
            const Radius.circular(2),
          ), carbonPlate);
          // Sol Baldır Plakası
          canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTRB(center.dx - 13.0, center.dy + 31.5, center.dx - 4.0, center.dy + 45),
            const Radius.circular(2),
          ), carbonPlate);
          // Sağ Baldır Plakası
          canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTRB(center.dx + 4.0, center.dy + 31.5, center.dx + 13.0, center.dy + 45),
            const Radius.circular(2),
          ), carbonPlate);

          // 3. Sağ Uyluk Üzerinde Siber Hız Çizgileri (Hazard Stripes)
          final hatchPaint = Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.75)..style = PaintingStyle.stroke..strokeWidth = 1.0;
          canvas.drawLine(Offset(center.dx + 5.5, center.dy + 16), Offset(center.dx + 8.5, center.dy + 19), hatchPaint);
          canvas.drawLine(Offset(center.dx + 8.5, center.dy + 16), Offset(center.dx + 11.5, center.dy + 19), hatchPaint);

          // 4. Sol Uylukta Dikey Telemetri Durum LED'leri (Power & Sensor telemetry)
          canvas.drawRect(Rect.fromLTWH(center.dx - 12.8, center.dy + 15.0, 1.3, 1.3), Paint()..color = const Color(0xFF00E676)); // Yeşil
          canvas.drawRect(Rect.fromLTWH(center.dx - 12.8, center.dy + 17.2, 1.3, 1.3), Paint()..color = const Color(0xFF00E5FF)); // Cyan
          canvas.drawRect(Rect.fromLTWH(center.dx - 12.8, center.dy + 19.4, 1.3, 1.3), Paint()..color = const Color(0xFFFFB300)); // Turuncu
          // Sağ bacak baldır LED'i
          canvas.drawRect(Rect.fromLTWH(center.dx + 11.5, center.dy + 41.0, 1.3, 1.3), Paint()..color = const Color(0xFF00E5FF));

          // 5. Açılı Neon Siber Veri Yolları (Angled 45° Neural Bus Circuits)
          // Sol bacak devre yolu
          final leftBus = Path()
            ..moveTo(center.dx - 11.0, center.dy + 12)
            ..lineTo(center.dx - 11.0, center.dy + 17)
            ..lineTo(center.dx - 8.0, center.dy + 21)
            ..lineTo(center.dx - 8.0, center.dy + 24);
          canvas.drawPath(leftBus, neonLine);
          final leftShinBus = Path()
            ..moveTo(center.dx - 8.0, center.dy + 29)
            ..lineTo(center.dx - 8.0, center.dy + 34)
            ..lineTo(center.dx - 11.0, center.dy + 38)
            ..lineTo(center.dx - 11.0, center.dy + 45);
          canvas.drawPath(leftShinBus, neonLine);

          // Sağ bacak devre yolu
          final rightBus = Path()
            ..moveTo(center.dx + 11.0, center.dy + 12)
            ..lineTo(center.dx + 11.0, center.dy + 17)
            ..lineTo(center.dx + 8.0, center.dy + 21)
            ..lineTo(center.dx + 8.0, center.dy + 24);
          canvas.drawPath(rightBus, neonLine);
          final rightShinBus = Path()
            ..moveTo(center.dx + 8.0, center.dy + 29)
            ..lineTo(center.dx + 8.0, center.dy + 34)
            ..lineTo(center.dx + 11.0, center.dy + 38)
            ..lineTo(center.dx + 11.0, center.dy + 45);
          canvas.drawPath(rightShinBus, neonLine);

          // Devre lehim nodları (Glow dots)
          canvas.drawCircle(Offset(center.dx - 11.0, center.dy + 12), 1.2, neonCyan);
          canvas.drawCircle(Offset(center.dx - 11.0, center.dy + 45), 1.2, neonCyan);
          canvas.drawCircle(Offset(center.dx + 11.0, center.dy + 12), 1.2, neonCyan);
          canvas.drawCircle(Offset(center.dx + 11.0, center.dy + 45), 1.2, neonCyan);

          // 6. Titanyum Kinetik Diz Servoları & Füzyon Reaktör Çekirdeği
          void drawKneeServo(double kx) {
            // Dış titanyum yuva
            canvas.drawRRect(RRect.fromRectAndRadius(
              Rect.fromLTRB(kx - 4.5, center.dy + 23.5, kx + 4.5, center.dy + 29.5),
              const Radius.circular(2.5),
            ), servoTitanium);
            canvas.drawRRect(RRect.fromRectAndRadius(
              Rect.fromLTRB(kx - 4.5, center.dy + 23.5, kx + 4.5, center.dy + 29.5),
              const Radius.circular(2.5),
            ), Paint()..color = const Color(0xFF607D8B)..style = PaintingStyle.stroke..strokeWidth = 0.8);

            // Reaktör enerji aurası ve parlama
            canvas.drawCircle(Offset(kx, center.dy + 26.5), 3.5, neonGlow);
            canvas.drawCircle(Offset(kx, center.dy + 26.5), 2.2, neonCyan);
            canvas.drawCircle(Offset(kx, center.dy + 26.5), 1.0, Paint()..color = Colors.white);
          }
          drawKneeServo(center.dx - 8);
          drawKneeServo(center.dx + 8);

          // 7. Bel Kemeri ve Güç Aktarım Hattı
          canvas.drawRect(Rect.fromLTRB(center.dx - 13.5, center.dy + 11, center.dx + 13.5, center.dy + 14.5), Paint()..color = const Color(0xFF14191E));
          canvas.drawLine(Offset(center.dx - 10, center.dy + 12.8), Offset(center.dx + 10, center.dy + 12.8), Paint()..color = const Color(0xFF00E5FF)..strokeWidth = 0.9);
          canvas.drawRect(Rect.fromLTRB(center.dx - 2.5, center.dy + 11.5, center.dx + 2.5, center.dy + 14.0), servoTitanium);
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
    // Kıyafet kuşanıldığında nefes alma animasyonunda kemer altından ten rengi sızmasını önlemek için
    // ten gövdesi kemer sınırını (center.dy + 10) geçmeyecek şekilde sınırlandırılır.
    final double skinTorsoBottom = torsoId.isNotEmpty
        ? min(torsoBottom - 2.5, center.dy + 10.0)
        : torsoBottom;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(center.dx - 14.5, torsoTop, center.dx + 14.5, skinTorsoBottom),
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
        // Şık Takım Elbise Ceketi: Özel dikim kuplu gövde, sivri klapalar, beyaz gömlek, kırmızı ipek kravat, kravat iğnesi, cep mendili ve manşetler
        final suitBase = Paint()..color = const Color(0xFF1E293B)..style = PaintingStyle.fill;
        final suitLapel = Paint()..color = const Color(0xFF0F172A)..style = PaintingStyle.fill;
        final shirtWhite = Paint()..color = const Color(0xFFFFFFFF)..style = PaintingStyle.fill;
        final tieRed = Paint()..color = const Color(0xFFC62828)..style = PaintingStyle.fill;
        final tieDark = Paint()..color = const Color(0xFF8E0000)..style = PaintingStyle.fill;
        final goldDetail = Paint()..color = const Color(0xFFFFD54F)..style = PaintingStyle.fill;

        // 1. Ceket Gövdesi (Nefes alma efektinde ten sızmasını tamamen engelleyecek şekilde torsoBottom + 3.5'e uzatıldı)
        final jacketHemBottom = torsoBottom + 3.5;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 16, torsoTop - 1, center.dx + 16, jacketHemBottom),
          const Radius.circular(4),
        ), suitBase);

        // Ceket ön yırtmaç / kavisli etek ucu kesimi (Bespoke Cutaway)
        final cutawayPath = Path()
          ..moveTo(center.dx - 3.5, jacketHemBottom)
          ..quadraticBezierTo(center.dx, jacketHemBottom - 2.5, center.dx + 3.5, jacketHemBottom)
          ..close();
        canvas.drawPath(cutawayPath, Paint()..color = Colors.black26);

        // 2. Kollar ve Beyaz Gömlek Manşetleri
        // Sol kol
        canvas.drawRRect(RRect.fromRectAndCorners(
          Rect.fromLTRB(center.dx - 22, torsoTop + 3.5, center.dx - 14, torsoBottom + 0.5),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        ), suitBase);
        // Sol kol manşetinden taşan beyaz gömlek ve kol düğmesi
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 21.5, torsoBottom + 0.5, center.dx - 14.5, torsoBottom + 2.2),
          const Radius.circular(1.0),
        ), shirtWhite);
        canvas.drawCircle(Offset(center.dx - 18, torsoBottom + 1.3), 0.7, goldDetail);

        // Sağ kol
        canvas.drawRRect(RRect.fromRectAndCorners(
          Rect.fromLTRB(center.dx + 14, torsoTop + 3.5, center.dx + 22, torsoBottom + 0.5),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        ), suitBase);
        // Sağ kol manşetinden taşan beyaz gömlek ve kol düğmesi
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx + 14.5, torsoBottom + 0.5, center.dx + 21.5, torsoBottom + 2.2),
          const Radius.circular(1.0),
        ), shirtWhite);
        canvas.drawCircle(Offset(center.dx + 18, torsoBottom + 1.3), 0.7, goldDetail);

        // Kol bilek ceket düğmeleri (Her iki kolda minik düğmeler)
        final sleeveBtn = Paint()..color = Colors.black54..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(center.dx - 16, torsoBottom - 1.5), 0.8, sleeveBtn);
        canvas.drawCircle(Offset(center.dx - 16, torsoBottom - 4.0), 0.8, sleeveBtn);
        canvas.drawCircle(Offset(center.dx + 16, torsoBottom - 1.5), 0.8, sleeveBtn);
        canvas.drawCircle(Offset(center.dx + 16, torsoBottom - 4.0), 0.8, sleeveBtn);

        // 3. Beyaz Gömlek & Dik Yaka Uçları
        final shirtVPath = Path()
          ..moveTo(center.dx - 6.5, torsoTop - 1)
          ..lineTo(center.dx + 6.5, torsoTop - 1)
          ..lineTo(center.dx, torsoTop + 12.0)
          ..close();
        canvas.drawPath(shirtVPath, shirtWhite);

        // Gömlek yakası sivri kanatları (Folded Collar Wings)
        final leftWing = Path()
          ..moveTo(center.dx - 6.0, torsoTop - 1)
          ..lineTo(center.dx - 2.2, torsoTop + 3.5)
          ..lineTo(center.dx - 4.5, torsoTop + 2.5)
          ..close();
        canvas.drawPath(leftWing, Paint()..color = const Color(0xFFF1F5F9));
        final rightWing = Path()
          ..moveTo(center.dx + 6.0, torsoTop - 1)
          ..lineTo(center.dx + 2.2, torsoTop + 3.5)
          ..lineTo(center.dx + 4.5, torsoTop + 2.5)
          ..close();
        canvas.drawPath(rightWing, Paint()..color = const Color(0xFFF1F5F9));

        // 4. Kırmızı İpek Kravat & Altın Kravat İğnesi
        // Kravat düğümü (Trapezoid)
        final tieKnot = Path()
          ..moveTo(center.dx - 2.0, torsoTop)
          ..lineTo(center.dx + 2.0, torsoTop)
          ..lineTo(center.dx + 1.6, torsoTop + 3.2)
          ..lineTo(center.dx - 1.6, torsoTop + 3.2)
          ..close();
        canvas.drawPath(tieKnot, tieDark);

        // Kravat gövdesi ve sivri elmas ucu
        final tieBlade = Path()
          ..moveTo(center.dx - 1.6, torsoTop + 3.2)
          ..lineTo(center.dx + 1.6, torsoTop + 3.2)
          ..lineTo(center.dx + 2.4, torsoTop + 11.5)
          ..lineTo(center.dx, torsoTop + 14.5)
          ..lineTo(center.dx - 2.4, torsoTop + 11.5)
          ..close();
        canvas.drawPath(tieBlade, tieRed);

        // Kravat gölge derinliği
        final tieShade = Path()
          ..moveTo(center.dx, torsoTop + 3.2)
          ..lineTo(center.dx + 1.6, torsoTop + 3.2)
          ..lineTo(center.dx + 2.4, torsoTop + 11.5)
          ..lineTo(center.dx, torsoTop + 14.5)
          ..close();
        canvas.drawPath(tieShade, tieDark);

        // Altın Kravat İğnesi (Tie Clip)
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 1.5, torsoTop + 7.2, center.dx + 3.0, torsoTop + 8.2),
          const Radius.circular(0.5),
        ), goldDetail);
        canvas.drawCircle(Offset(center.dx + 0.5, torsoTop + 7.7), 0.4, Paint()..color = Colors.white);

        // 5. Keskin Peaked Klapalar (Sivri Yaka Kıvrımları)
        // Sol klapa
        final leftLapel = Path()
          ..moveTo(center.dx - 6.5, torsoTop - 1)
          ..lineTo(center.dx - 11.5, torsoTop + 5.5) // Sivri tepe ucu
          ..lineTo(center.dx - 9.0, torsoTop + 7.0)  // Yaka oyuğu (notch)
          ..lineTo(center.dx - 1.2, torsoTop + 13.5) // Düğme hizasına iniş
          ..lineTo(center.dx - 4.5, torsoTop + 11.5)
          ..close();
        canvas.drawPath(leftLapel, suitLapel);
        canvas.drawPath(leftLapel, Paint()..color = const Color(0xFF334155)..style = PaintingStyle.stroke..strokeWidth = 0.8);

        // Sağ klapa
        final rightLapel = Path()
          ..moveTo(center.dx + 6.5, torsoTop - 1)
          ..lineTo(center.dx + 11.5, torsoTop + 5.5)
          ..lineTo(center.dx + 9.0, torsoTop + 7.0)
          ..lineTo(center.dx + 1.2, torsoTop + 13.5)
          ..lineTo(center.dx + 4.5, torsoTop + 11.5)
          ..close();
        canvas.drawPath(rightLapel, suitLapel);
        canvas.drawPath(rightLapel, Paint()..color = const Color(0xFF334155)..style = PaintingStyle.stroke..strokeWidth = 0.8);

        // 6. Sol Göğüs Cebi ve Beyaz İpek Mendil (Pocket Square / Pochette)
        // Cep şeridi
        canvas.drawLine(
          Offset(center.dx - 14.5, torsoTop + 8.5),
          Offset(center.dx - 9.0, torsoTop + 8.0),
          Paint()..color = const Color(0xFF0F172A)..strokeWidth = 1.4,
        );
        // Katlanmış sivri ipek mendil
        final pochette = Path()
          ..moveTo(center.dx - 13.5, torsoTop + 8.0)
          ..lineTo(center.dx - 12.0, torsoTop + 5.2) // Sol tepe
          ..lineTo(center.dx - 10.8, torsoTop + 7.5)
          ..lineTo(center.dx - 9.8, torsoTop + 6.0)  // Sağ tepe
          ..lineTo(center.dx - 9.2, torsoTop + 8.0)
          ..close();
        canvas.drawPath(pochette, shirtWhite);
        canvas.drawPath(pochette, Paint()..color = const Color(0xFFCBD5E1)..style = PaintingStyle.stroke..strokeWidth = 0.5);

        // 7. Parlak Çift Altın Ceket Düğmesi (Center Closure)
        // Üst düğme
        canvas.drawCircle(Offset(center.dx, torsoTop + 14.5), 1.6, goldDetail);
        canvas.drawCircle(Offset(center.dx, torsoTop + 14.5), 0.6, Paint()..color = Colors.brown.shade900);
        // Alt düğme
        canvas.drawCircle(Offset(center.dx, torsoTop + 19.0), 1.6, goldDetail);
        canvas.drawCircle(Offset(center.dx, torsoTop + 19.0), 0.6, Paint()..color = Colors.brown.shade900);
      } else if (torsoId == 'steel_chestplate') {
        // Çelik Göğüslük: Ağır şövalye zırhı, katmanlı omuzluklar ve anatomik göğüs plakası
        final steelDark = Paint()..color = const Color(0xFF37474F)..style = PaintingStyle.fill;
        final steelMain = Paint()..color = const Color(0xFF607D8B)..style = PaintingStyle.fill;
        final steelLight = Paint()..color = const Color(0xFF90A4AE)..style = PaintingStyle.fill;
        final steelHighlight = Paint()..color = const Color(0xFFCFD8DC)..style = PaintingStyle.fill;

        // 1. Zırh Altı Gambeson / Zincir Zırh Kollukları (Kolları gövdeye bağlayan kumaş zırh)
        final underSleeve = Paint()..color = const Color(0xFF455A64)..style = PaintingStyle.fill;
        // Sol kol
        canvas.drawRRect(RRect.fromRectAndCorners(
          Rect.fromLTRB(center.dx - 22, torsoTop + 3, center.dx - 14, torsoTop + 16),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        ), underSleeve);
        // Sağ kol
        canvas.drawRRect(RRect.fromRectAndCorners(
          Rect.fromLTRB(center.dx + 14, torsoTop + 3, center.dx + 22, torsoTop + 16),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        ), underSleeve);
        // Kolluk deri manşetleri
        final cuffPaint = Paint()..color = const Color(0xFF263238)..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTRB(center.dx - 22, torsoTop + 14, center.dx - 14, torsoTop + 16), cuffPaint);
        canvas.drawRect(Rect.fromLTRB(center.dx + 14, torsoTop + 14, center.dx + 22, torsoTop + 16), cuffPaint);

        // 2. Çelik Göğüs Zırhı Gövdesi (Anatomik şövalye cuirass)
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 16, torsoTop - 2, center.dx + 16, torsoBottom + 1),
          const Radius.circular(6),
        ), steelMain);

        // Boyun Boğazlık Zırhı (Gorget)
        final gorgetPath = Path()
          ..moveTo(center.dx - 7, torsoTop - 2)
          ..lineTo(center.dx + 7, torsoTop - 2)
          ..lineTo(center.dx + 5, torsoTop + 4)
          ..lineTo(center.dx - 5, torsoTop + 4)
          ..close();
        canvas.drawPath(gorgetPath, steelDark);

        // Göğüs Pektoral Plakaları (Anatomik açılı çelik kıvrımlar)
        final chestShade = Path()
          ..moveTo(center.dx - 14, torsoTop + 3)
          ..lineTo(center.dx, torsoTop + 8)
          ..lineTo(center.dx + 14, torsoTop + 3)
          ..lineTo(center.dx + 12, torsoTop + 12)
          ..lineTo(center.dx, torsoTop + 15)
          ..lineTo(center.dx - 12, torsoTop + 12)
          ..close();
        canvas.drawPath(chestShade, steelLight);

        // Merkezi Çelik Darbe Kırıcı Omurga (Central Tapul / Deflection Ridge)
        final ridgePaint = Paint()
          ..color = steelHighlight.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
        canvas.drawLine(Offset(center.dx, torsoTop + 2), Offset(center.dx, torsoBottom - 2), ridgePaint);

        // Bel Eklem Plakaları (Segmented Fauld Plates)
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 15, torsoBottom - 6, center.dx + 15, torsoBottom - 2),
          const Radius.circular(2),
        ), steelDark);
        // Altın/Pirinç Zırh Perçinleri
        final rivet = Paint()..color = const Color(0xFFFFB300)..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(center.dx - 12, torsoBottom - 4), 1.0, rivet);
        canvas.drawCircle(Offset(center.dx + 12, torsoBottom - 4), 1.0, rivet);
        canvas.drawCircle(Offset(center.dx - 12, torsoTop + 1), 1.0, rivet);
        canvas.drawCircle(Offset(center.dx + 12, torsoTop + 1), 1.0, rivet);

        // 3. Ağır Katmanlı Şövalye Omuzlukları (Heavy Tiered Pauldrons)
        // Sol Omuzluk (3 katmanlı çelik zırh)
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(center.dx - 23, torsoTop, center.dx - 13, torsoTop + 7), const Radius.circular(3)), steelDark);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(center.dx - 22.5, torsoTop + 5, center.dx - 13.5, torsoTop + 11), const Radius.circular(2.5)), steelMain);
        canvas.drawCircle(Offset(center.dx - 18, torsoTop + 3.5), 1.2, steelHighlight);
        // Sağ Omuzluk (3 katmanlı çelik zırh)
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(center.dx + 13, torsoTop, center.dx + 23, torsoTop + 7), const Radius.circular(3)), steelDark);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(center.dx + 13.5, torsoTop + 5, center.dx + 22.5, torsoTop + 11), const Radius.circular(2.5)), steelMain);
        canvas.drawCircle(Offset(center.dx + 18, torsoTop + 3.5), 1.2, steelHighlight);
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
        // Işık Zırhı: Kutsal gümüş zırh, kanatlı altın omuzluklar ve parıldayan ışık çekirdeği
        final silverMain = Paint()..color = const Color(0xFFECEFF1)..style = PaintingStyle.fill;
        final goldTrim = Paint()..color = const Color(0xFFFFB300)..style = PaintingStyle.fill;
        final goldLight = Paint()..color = const Color(0xFFFFD54F)..style = PaintingStyle.fill;
        final royalBlue = Paint()..color = const Color(0xFF1A237E)..style = PaintingStyle.fill;

        // 1. Kutsal Kraliyet Kollukları (Safir mavisi kumaş + altın varak)
        // Sol kol
        canvas.drawRRect(RRect.fromRectAndCorners(
          Rect.fromLTRB(center.dx - 22, torsoTop + 3, center.dx - 14, torsoTop + 17),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        ), royalBlue);
        // Sağ kol
        canvas.drawRRect(RRect.fromRectAndCorners(
          Rect.fromLTRB(center.dx + 14, torsoTop + 3, center.dx + 22, torsoTop + 17),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        ), royalBlue);
        // Kol altın manşetleri
        canvas.drawRect(Rect.fromLTRB(center.dx - 22, torsoTop + 14.5, center.dx - 14, torsoTop + 16.5), goldLight);
        canvas.drawRect(Rect.fromLTRB(center.dx + 14, torsoTop + 14.5, center.dx + 22, torsoTop + 16.5), goldLight);

        // 2. Parlak Gümüş Göğüslük & Altın İşlemeler (Paladin Cuirass)
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 16, torsoTop - 2.5, center.dx + 16, torsoBottom + 2),
          const Radius.circular(6),
        ), silverMain);

        // Altın dış çerçeve ve kenar süslemeleri
        final goldBorder = Paint()..color = goldTrim.color..style = PaintingStyle.stroke..strokeWidth = 1.5;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 15, torsoTop - 1.5, center.dx + 15, torsoBottom + 1),
          const Radius.circular(5),
        ), goldBorder);

        // Merkez Kutsal Tabard (Safir ve altın dikey kuşak)
        canvas.drawRect(Rect.fromLTRB(center.dx - 4, torsoTop - 1, center.dx + 4, torsoBottom + 1), royalBlue);
        canvas.drawLine(
          Offset(center.dx, torsoTop - 1),
          Offset(center.dx, torsoBottom + 1),
          Paint()..color = goldLight.color..strokeWidth = 1.0,
        );

        // Altın Kemer & Işık Tokası
        canvas.drawRect(Rect.fromLTRB(center.dx - 16, torsoBottom - 5, center.dx + 16, torsoBottom), goldTrim);
        canvas.drawCircle(Offset(center.dx, torsoBottom - 2.5), 2.2, Paint()..color = Colors.white);

        // 3. Kanatlı Kutsal Altın Omuzluklar (Divine Winged Pauldrons)
        // Sol kanatlı omuzluk
        final leftWing = Path()
          ..moveTo(center.dx - 13, torsoTop - 1)
          ..quadraticBezierTo(center.dx - 24, torsoTop - 1.5, center.dx - 23, torsoTop + 7)
          ..lineTo(center.dx - 13.5, torsoTop + 12)
          ..close();
        canvas.drawPath(leftWing, goldLight);
        canvas.drawPath(leftWing, Paint()..color = goldTrim.color..style = PaintingStyle.stroke..strokeWidth = 0.9);

        // Sağ kanatlı omuzluk
        final rightWing = Path()
          ..moveTo(center.dx + 13, torsoTop - 1)
          ..quadraticBezierTo(center.dx + 24, torsoTop - 1.5, center.dx + 23, torsoTop + 7)
          ..lineTo(center.dx + 13.5, torsoTop + 12)
          ..close();
        canvas.drawPath(rightWing, goldLight);
        canvas.drawPath(rightWing, Paint()..color = goldTrim.color..style = PaintingStyle.stroke..strokeWidth = 0.9);

        // 4. Parlayan Kutsal Işık Kristali (Aura & Crystal Core)
        // Dış ışık aurası (Pulsing holy glow)
        canvas.drawCircle(Offset(center.dx, torsoTop + 7), 5.5, Paint()..color = Colors.cyanAccent.withValues(alpha: 0.35));
        // Altın çerçeve yuvası
        canvas.drawCircle(Offset(center.dx, torsoTop + 7), 4.2, goldTrim);
        // Kristal göbek
        canvas.drawCircle(Offset(center.dx, torsoTop + 7), 3.2, Paint()..color = Colors.cyanAccent);
        // Beyaz kutsal ışık parlaması
        canvas.drawCircle(Offset(center.dx, torsoTop + 7), 1.6, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(center.dx - 0.8, torsoTop + 6), 0.6, Paint()..color = Colors.white);
      } else if (torsoId == 'cyber_suit') {
        // Siber Nano Zırh: Karbon fiber zırh, neon devre hatları ve kuantum reaktör çekirdeği
        final carbonBase = Paint()..color = const Color(0xFF1E272E)..style = PaintingStyle.fill;
        final carbonPlate = Paint()..color = const Color(0xFF2C3E50)..style = PaintingStyle.fill;
        final neonCyan = Paint()..color = const Color(0xFF00E5FF)..style = PaintingStyle.fill;
        final neonLine = Paint()..color = const Color(0xFF18FFFF)..style = PaintingStyle.stroke..strokeWidth = 1.0;

        // 1. Karbon Nano Kolluklar (Kolları saran siber lifler ve neon devreler)
        // Sol kol
        canvas.drawRRect(RRect.fromRectAndCorners(
          Rect.fromLTRB(center.dx - 22, torsoTop + 3, center.dx - 14, torsoTop + 17),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        ), carbonBase);
        // Sağ kol
        canvas.drawRRect(RRect.fromRectAndCorners(
          Rect.fromLTRB(center.dx + 14, torsoTop + 3, center.dx + 22, torsoTop + 17),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        ), carbonBase);
        // Kollardaki neon devre hatları
        canvas.drawLine(Offset(center.dx - 18, torsoTop + 5), Offset(center.dx - 18, torsoTop + 15), neonLine..strokeWidth = 0.8);
        canvas.drawLine(Offset(center.dx + 18, torsoTop + 5), Offset(center.dx + 18, torsoTop + 15), neonLine..strokeWidth = 0.8);

        // 2. Nano Plakalı Gövde Zırhı (Exosuit Body - torsoBottom + 3.5'e uzatılarak nefes almadaki ten sızıntısı tamamen engellendi)
        final nanoBottom = torsoBottom + 3.5;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 16, torsoTop - 2, center.dx + 16, nanoBottom),
          const Radius.circular(5),
        ), carbonBase);

        // Göğüs & Karın Zırh Plakaları
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 14, torsoTop + 1, center.dx + 14, torsoTop + 12),
          const Radius.circular(3),
        ), carbonPlate);
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 13, torsoTop + 13.5, center.dx + 13, nanoBottom - 2),
          const Radius.circular(2),
        ), carbonPlate);

        // Siber Kemer & Pelvik Zırh Kilidi (Pantolon ile kusursuz birleşir)
        final nanoBeltRect = Rect.fromLTRB(center.dx - 14.5, torsoBottom - 1.5, center.dx + 14.5, nanoBottom);
        canvas.drawRRect(RRect.fromRectAndRadius(nanoBeltRect, const Radius.circular(2.5)), carbonBase);
        // Kemer üzeri neon güç hücresi
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 2.8, torsoBottom, center.dx + 2.8, nanoBottom - 1.0),
          const Radius.circular(1.0),
        ), neonCyan);
        canvas.drawCircle(Offset(center.dx, torsoBottom + 1.2), 0.7, Paint()..color = Colors.white);

        // 3. Fütüristik Açılı Siber Omuzluklar (Nano Pauldrons)
        // Sol omuzluk
        final leftShoulder = Path()
          ..moveTo(center.dx - 14, torsoTop - 1)
          ..lineTo(center.dx - 23, torsoTop + 1)
          ..lineTo(center.dx - 22, torsoTop + 10)
          ..lineTo(center.dx - 14, torsoTop + 7)
          ..close();
        canvas.drawPath(leftShoulder, carbonPlate);
        canvas.drawPath(leftShoulder, neonLine);
        // Sol omuz telemetri LED'i
        canvas.drawCircle(Offset(center.dx - 18, torsoTop + 4), 0.9, Paint()..color = const Color(0xFF00E676));

        // Sağ omuzluk
        final rightShoulder = Path()
          ..moveTo(center.dx + 14, torsoTop - 1)
          ..lineTo(center.dx + 23, torsoTop + 1)
          ..lineTo(center.dx + 22, torsoTop + 10)
          ..lineTo(center.dx + 14, torsoTop + 7)
          ..close();
        canvas.drawPath(rightShoulder, carbonPlate);
        canvas.drawPath(rightShoulder, neonLine);
        // Sağ omuz telemetri LED'i
        canvas.drawCircle(Offset(center.dx + 18, torsoTop + 4), 0.9, neonCyan);

        // 4. Göğüs Kuantum Ark Reaktörü (Nano Core)
        // Reaktör enerji aurası
        canvas.drawCircle(Offset(center.dx, torsoTop + 6.5), 5.2, Paint()..color = const Color(0x4000E5FF));
        // Reaktör dış titanyum halkası
        canvas.drawCircle(Offset(center.dx, torsoTop + 6.5), 4.0, carbonBase);
        // Reaktör neon camgöbeği çekirdeği
        canvas.drawCircle(Offset(center.dx, torsoTop + 6.5), 3.0, neonCyan);
        // Kuantum füzyon merkezi (Beyaz ışık)
        canvas.drawCircle(Offset(center.dx, torsoTop + 6.5), 1.4, Paint()..color = Colors.white);

        // Reaktörden omuzlara ve gövdeye dağılan neon güç hatları
        final busLine = Paint()..color = const Color(0xFF18FFFF)..style = PaintingStyle.stroke..strokeWidth = 1.0;
        canvas.drawLine(Offset(center.dx - 4, torsoTop + 6.5), Offset(center.dx - 13, torsoTop + 6.5), busLine);
        canvas.drawLine(Offset(center.dx + 4, torsoTop + 6.5), Offset(center.dx + 13, torsoTop + 6.5), busLine);
        canvas.drawLine(Offset(center.dx, torsoTop + 10.5), Offset(center.dx, torsoTop + 17), busLine);
        canvas.drawLine(Offset(center.dx - 7, torsoTop + 18), Offset(center.dx + 7, torsoTop + 18), busLine);
      }
    } else {
      // Temel Kıyafet (Giysi kuşanılmamışsa): Şık, katmanlı casual tişört ve kollar
      final shirtNavy = Paint()..color = const Color(0xFF334155)..style = PaintingStyle.fill;
      final whiteLayer = Paint()..color = const Color(0xFFF1F5F9)..style = PaintingStyle.fill;

      // 1. Tişört Kısa Kolları (Kolları saran şık dikişli kollar - çıplak/kopuk kolları engeller!)
      // Sol kol
      canvas.drawRRect(RRect.fromRectAndCorners(
        Rect.fromLTRB(center.dx - 22, torsoTop + 5, center.dx - 14, torsoTop + 15),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
        bottomLeft: const Radius.circular(2),
        bottomRight: const Radius.circular(2),
      ), shirtNavy);
      // Sol kol beyaz iç tişört astarı
      canvas.drawRect(Rect.fromLTRB(center.dx - 22, torsoTop + 13.5, center.dx - 14, torsoTop + 15), whiteLayer);

      // Sağ kol
      canvas.drawRRect(RRect.fromRectAndCorners(
        Rect.fromLTRB(center.dx + 14, torsoTop + 5, center.dx + 22, torsoTop + 15),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
        bottomLeft: const Radius.circular(2),
        bottomRight: const Radius.circular(2),
      ), shirtNavy);
      // Sağ kol beyaz iç tişört astarı
      canvas.drawRect(Rect.fromLTRB(center.dx + 14, torsoTop + 13.5, center.dx + 22, torsoTop + 15), whiteLayer);

      // 2. Tişört Gövdesi (Lacivert/Antrasit modern kesim)
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(center.dx - 14.5, torsoTop, center.dx + 14.5, torsoBottom),
        const Radius.circular(5),
      ), shirtNavy);

      // Beyaz iç yaka detayı (Layered crewneck collar)
      canvas.drawOval(Rect.fromLTRB(center.dx - 5.5, torsoTop - 1, center.dx + 5.5, torsoTop + 5), whiteLayer);
      canvas.drawArc(
        Rect.fromLTRB(center.dx - 4.5, torsoTop, center.dx + 4.5, torsoTop + 4),
        0, pi, false,
        Paint()..color = const Color(0xFF1E293B)..style = PaintingStyle.stroke..strokeWidth = 1.3,
      );

      // Göğüste şık minimalist Ascend amblemi
      final emblemPaint = Paint()..color = const Color(0xFF38BDF8)..style = PaintingStyle.stroke..strokeWidth = 1.1;
      final emblemPath = Path()
        ..moveTo(center.dx - 8.5, torsoTop + 8.5)
        ..lineTo(center.dx - 6.5, torsoTop + 6.5)
        ..lineTo(center.dx - 4.5, torsoTop + 8.5);
      canvas.drawPath(emblemPath, emblemPaint);

      // Etek dikiş çizgisi
      final hemLine = Paint()..color = const Color(0xFF1E293B)..style = PaintingStyle.stroke..strokeWidth = 1.0;
      canvas.drawLine(Offset(center.dx - 14.5, torsoBottom - 2), Offset(center.dx + 14.5, torsoBottom - 2), hemLine);
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
    final bool showHair = hatId != 'iron_helmet' && hatId != 'ninja_mask';
    const hairMainColor = Color(0xFF3E2723); // Zengin espresso kahverengi
    const hairLightColor = Color(0xFF5D4037); // Doğal saç ışıltısı / katman

    if (showHair) {
      final hairPaint = Paint()..color = hairMainColor..style = PaintingStyle.fill;
      final hairHighlight = Paint()..color = hairLightColor..style = PaintingStyle.fill;

      final bool fullTopVisible = hatId.isEmpty || hatId == 'bandana' || hatId == 'crown' || hatId == 'cyber_visor';

      // 1. TAM VE BÜTÜN DOĞAL SAÇ GÖVDESİ (Kral tacındakiyle ve referans görselle birebir aynı tam model)
      final fullHairPath = Path()
        // Sol favori sivri ucu
        ..moveTo(center.dx - 15.0, headY + 3.0)
        // Sol yanak ve kulak önü hattı
        ..quadraticBezierTo(center.dx - 16.5, headY - 1.0, center.dx - 17.0, headY - 5.0)
        // Sol şakak doğal hacim dalgası 1
        ..quadraticBezierTo(center.dx - 18.2, headY - 8.0, center.dx - 16.8, headY - 10.5)
        // Sol şakak doğal hacim dalgası 2
        ..quadraticBezierTo(center.dx - 18.0, headY - 13.0, center.dx - 15.5, headY - 15.5)
        // Sol tepe kubbe kavisi
        ..quadraticBezierTo(center.dx - 11.0, headY - 18.5, center.dx - 5.0, headY - 18.8)
        // Tepe merkez dokusu ve saç ayrımı (Hacimli organik tepe)
        ..quadraticBezierTo(center.dx - 1.0, headY - 19.2, center.dx + 2.0, headY - 18.8)
        ..quadraticBezierTo(center.dx + 7.0, headY - 18.8, center.dx + 12.0, headY - 17.5)
        // Sağ tepe ve şakak kavisi
        ..quadraticBezierTo(center.dx + 16.2, headY - 14.8, center.dx + 17.2, headY - 11.0)
        ..quadraticBezierTo(center.dx + 17.8, headY - 6.5, center.dx + 16.8, headY - 2.5)
        // Sağ favori ucu
        ..quadraticBezierTo(center.dx + 16.2, headY + 0.5, center.dx + 15.0, headY + 3.0)

        // 2. İÇ ALIN KONTURU VE YANA TARANMIŞ KAKÜLLER (Referans görseldeki yana dökülen katmanlar)
        // Sağ favori iç hattından yukarı çıkış
        ..quadraticBezierTo(center.dx + 13.8, headY + 0.5, center.dx + 13.5, headY - 2.5)

        // Sağdaki hafif tüy tutamlar (Referans görselin sağındaki ince dökülen teller)
        // İnce Tutam 1 (En sağ)
        ..quadraticBezierTo(center.dx + 13.0, headY - 4.5, center.dx + 12.2, headY - 5.8)
        ..quadraticBezierTo(center.dx + 11.8, headY - 7.5, center.dx + 11.2, headY - 9.0)
        // İnce Tutam 2 (Sağ-orta)
        ..quadraticBezierTo(center.dx + 10.6, headY - 7.0, center.dx + 9.8, headY - 6.2)
        ..quadraticBezierTo(center.dx + 9.0, headY - 8.0, center.dx + 8.5, headY - 9.2)
        // İnce Tutam 3 (Sağ iç)
        ..quadraticBezierTo(center.dx + 7.8, headY - 7.2, center.dx + 7.0, headY - 6.0)
        ..quadraticBezierTo(center.dx + 6.2, headY - 7.8, center.dx + 5.5, headY - 9.0)

        // Orta-Sağ yana dökülen katmanlı ana tutam
        ..quadraticBezierTo(center.dx + 4.2, headY - 7.0, center.dx + 2.8, headY - 5.5)
        ..quadraticBezierTo(center.dx + 1.8, headY - 7.2, center.dx + 1.0, headY - 8.8)

        // Merkezdeki karizmatik yana taranmış ana dalga (Referans görseldeki ana kıvrım)
        ..quadraticBezierTo(center.dx - 0.5, headY - 7.0, center.dx - 1.8, headY - 5.2)
        ..quadraticBezierTo(center.dx - 3.2, headY - 7.2, center.dx - 4.2, headY - 8.5)

        // Sol-Orta katmanlı tutam
        ..quadraticBezierTo(center.dx - 5.8, headY - 7.0, center.dx - 7.0, headY - 5.5)
        ..quadraticBezierTo(center.dx - 8.2, headY - 7.2, center.dx - 9.0, headY - 8.2)

        // Sol dış kavisli tutam
        ..quadraticBezierTo(center.dx - 10.5, headY - 6.8, center.dx - 11.8, headY - 5.2)
        ..quadraticBezierTo(center.dx - 12.8, headY - 3.5, center.dx - 13.5, headY - 2.0)

        // Sol favori iç hattından başlangıç noktasına dönüş
        ..quadraticBezierTo(center.dx - 13.8, headY + 0.5, center.dx - 15.0, headY + 3.0)
        ..close();

      canvas.save();
      if (!fullTopVisible) {
        // Kapalı şapkalarda (hasır şapka, bere, kovboy şapkası vb.) kubbeden saç taşmasını engellemek için
        // tepe kısmı şapka siperliği seviyesinden (headY - 7.0) kırpılır.
        // Yan favoriler ve kaküller KRAL TACINDAKİYLE BİREBİR AYNI, DOLGUN VE ŞIK ÇİZİLİR!
        canvas.clipRect(Rect.fromLTRB(center.dx - 25, headY - 7.0, center.dx + 25, headY + 20));
      }

      // Tek parça tam ve boşluksuz saç çizimi (Tüm şapkalarda kral tacındaki gibi dolgun yanlar!)
      canvas.drawPath(fullHairPath, hairPaint);

      // 3. ÖNE DÖKÜLEN HAFİF SAÇLAR & 3D DETAY HATLAR
      final fineStrandPaint = Paint()
        ..color = hairHighlight.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Sağdaki ince tüy tellerin akış çizgileri
      canvas.drawLine(
        Offset(center.dx + 10.8, headY - 8.5),
        Offset(center.dx + 10.0, headY - 6.0),
        fineStrandPaint..strokeWidth = 0.9,
      );
      canvas.drawLine(
        Offset(center.dx + 8.0, headY - 8.8),
        Offset(center.dx + 7.2, headY - 5.8),
        fineStrandPaint..strokeWidth = 0.9,
      );
      canvas.drawLine(
        Offset(center.dx + 4.2, headY - 8.5),
        Offset(center.dx + 3.0, headY - 5.5),
        fineStrandPaint..strokeWidth = 1.0,
      );

      // Merkez ana dalganın hafif kıvrım çizgisi
      final mainCurlLine = Path()
        ..moveTo(center.dx - 3.0, headY - 8.0)
        ..quadraticBezierTo(center.dx - 1.2, headY - 6.5, center.dx - 1.8, headY - 5.0);
      canvas.drawPath(mainCurlLine, fineStrandPaint..strokeWidth = 1.1);

      // Sol dalganın hafif akış çizgisi
      canvas.drawLine(
        Offset(center.dx - 8.0, headY - 8.0),
        Offset(center.dx - 7.0, headY - 5.6),
        fineStrandPaint..strokeWidth = 0.9,
      );

      if (fullTopVisible) {
        // Tepe Saç Işıltısı (Doğal hacim vurgusu)
        final crownSheen = Path()
          ..moveTo(center.dx - 8.5, headY - 15.0)
          ..quadraticBezierTo(center.dx, headY - 17.2, center.dx + 8.5, headY - 15.0)
          ..quadraticBezierTo(center.dx, headY - 16.0, center.dx - 8.5, headY - 15.0)
          ..close();
        canvas.drawPath(crownSheen, hairHighlight);
      }
      canvas.restore();
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
        // Geniş kenarlık (Kral tacındaki gibi saçların ve favorilerin dolgun görünmesini sağlar)
        canvas.drawOval(
          Rect.fromLTRB(center.dx - 25, headY - 11.5, center.dx + 25, headY - 5.8),
          hatPaint,
        );
        // Hasır kenarlık çizgisi
        final rimEdge = Paint()..color = Colors.brown.shade400..style = PaintingStyle.stroke..strokeWidth = 0.8;
        canvas.drawOval(
          Rect.fromLTRB(center.dx - 25, headY - 11.5, center.dx + 25, headY - 5.8),
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
        // Kovboy Şapkası: Klasik Cattleman kıvrımlı tepe, geniş kavisli siperlik ve altın yıldız
        final leatherMain = Paint()..color = const Color(0xFF6D4C41)..style = PaintingStyle.fill;
        final leatherLight = Paint()..color = const Color(0xFF8D6E63)..style = PaintingStyle.fill;
        final leatherDark = Paint()..color = const Color(0xFF4E342E)..style = PaintingStyle.fill;

        // 1. CATTLEMAN KROWN (Klasik Vadi Kıvrımlı Tepe Gövdesi)
        // Taban genişliği center.dx - 16 ile center.dx + 16 arası (kafayı tam kavrar!)
        final crownPath = Path()
          ..moveTo(center.dx - 16, headY - 8)
          ..lineTo(center.dx - 15, headY - 19)
          // Ortadaki klasik kovboy çöküntüsü (Cattleman crease)
          ..quadraticBezierTo(center.dx - 7, headY - 19.5, center.dx, headY - 16)
          ..quadraticBezierTo(center.dx + 7, headY - 19.5, center.dx + 15, headY - 19)
          ..lineTo(center.dx + 16, headY - 8)
          ..close();
        canvas.drawPath(crownPath, leatherMain);

        // Tepe Üstü 3D Işık & Kıvrım Gölgeleri
        final crownShade = Path()
          ..moveTo(center.dx - 12, headY - 8)
          ..lineTo(center.dx - 11, headY - 17.5)
          ..quadraticBezierTo(center.dx, headY - 14.5, center.dx + 11, headY - 17.5)
          ..lineTo(center.dx + 12, headY - 8)
          ..close();
        canvas.drawPath(crownShade, leatherLight);

        // Merkez Çöküntü Çizgisi (Kovboy şapkasının karakteristik tepe yarığı)
        final creaseLine = Paint()
          ..color = leatherDark.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawLine(Offset(center.dx, headY - 16), Offset(center.dx, headY - 10), creaseLine);

        // 2. GENİŞ KIVRIK KOVBOY SİPERLİĞİ (Gözleri gölgeleyen ve yanlardan yukarı kıvrılan tok kenarlık)
        final brimPath = Path()
          // Sol uçtan başla (yukarı kıvrık)
          ..moveTo(center.dx - 27, headY - 12)
          // Ön ortaya doğru inen kavis
          ..quadraticBezierTo(center.dx - 14, headY - 5.5, center.dx, headY - 6.5)
          // Sağ uca doğru yükselen kavis
          ..quadraticBezierTo(center.dx + 14, headY - 5.5, center.dx + 27, headY - 12)
          // Arka kenar kavisleri
          ..quadraticBezierTo(center.dx + 15, headY - 9.5, center.dx, headY - 10)
          ..quadraticBezierTo(center.dx - 15, headY - 9.5, center.dx - 27, headY - 12)
          ..close();
        canvas.drawPath(brimPath, leatherMain);

        // Siperlik alt derinlik çizgisi (3D görünüm için koyu kenar)
        final brimStroke = Paint()
          ..color = leatherDark.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawPath(brimPath, brimStroke);

        // 3. KOYU DERİ KEMER & PARLAK ŞERİF YILDIZI
        // Şapka kemeri (Koyu esmer deri şerit)
        final bandPath = Path()
          ..moveTo(center.dx - 16, headY - 7.5)
          ..lineTo(center.dx + 16, headY - 7.5)
          ..lineTo(center.dx + 15, headY - 11)
          ..lineTo(center.dx - 15, headY - 11)
          ..close();
        canvas.drawPath(bandPath, Paint()..color = const Color(0xFF2D1E18));

        // Şerif Yıldızı Tokası (Altın yıldız rozet)
        final starPaint = Paint()..color = const Color(0xFFFFC107)..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(center.dx, headY - 9.2), 2.2, starPaint);
        // Yıldız parıltısı
        canvas.drawCircle(Offset(center.dx - 0.5, headY - 9.7), 0.7, Paint()..color = Colors.white);
      } else if (hatId == 'iron_helmet') {
        // Demir Miğfer: Kafayı tamamen saran, boşluksuz şövalye zırhı
        final steelDark = Paint()..color = const Color(0xFF455A64)..style = PaintingStyle.fill;
        final steelMain = Paint()..color = const Color(0xFF607D8B)..style = PaintingStyle.fill;
        final steelLight = Paint()..color = const Color(0xFF90A4AE)..style = PaintingStyle.fill;
        final steelHighlight = Paint()..color = const Color(0xFFCFD8DC)..style = PaintingStyle.fill;

        // 1. TAM KAFA GÖVDESİ (Kafanın ten rengini 100% örten kubbe ve yanak/çene plakası)
        final fullHelmetPath = Path()
          // Üst kubbe
          ..moveTo(center.dx - 16.5, headY - 3)
          ..arcToPoint(
            Offset(center.dx + 16.5, headY - 3),
            radius: const Radius.elliptical(16.5, 17),
            clockwise: true,
          )
          // Sağ yanak ve çene koruması
          ..lineTo(center.dx + 16.5, headY + 8)
          ..quadraticBezierTo(center.dx + 14, headY + 11, center.dx + 8, headY + 11.5)
          ..lineTo(center.dx - 8, headY + 11.5)
          ..quadraticBezierTo(center.dx - 14, headY + 11, center.dx - 16.5, headY + 8)
          ..close();
        canvas.drawPath(fullHelmetPath, steelMain);

        // Miğfer Üst Kubbe Işık Yansıması (Kavisli metal parlama)
        final domeHighlight = Path()
          ..moveTo(center.dx - 13, headY - 8)
          ..arcToPoint(
            Offset(center.dx + 13, headY - 8),
            radius: const Radius.elliptical(13, 11),
            clockwise: true,
          )
          ..arcToPoint(
            Offset(center.dx - 13, headY - 8),
            radius: const Radius.elliptical(13, 8),
            clockwise: false,
          )
          ..close();
        canvas.drawPath(domeHighlight, steelLight);

        // 2. GÜÇLENDİRİLMİŞ ALIN BANDI (Brow reinforcement plate)
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 17, headY - 7.5, center.dx + 17, headY - 3.5),
          const Radius.circular(2),
        ), steelDark);
        // Alın bandı metal perçinleri (Rivets)
        canvas.drawCircle(Offset(center.dx - 14.5, headY - 5.5), 1.2, steelHighlight);
        canvas.drawCircle(Offset(center.dx + 14.5, headY - 5.5), 1.2, steelHighlight);
        canvas.drawCircle(Offset(center.dx, headY - 5.5), 1.4, steelHighlight);

        // 3. ŞÖVALYE SİPERLİĞİ & GÖZ YARIĞI (Visor Plate & Eye Slits)
        // Siperlik ön plakası (hafif öne çıkıntılı yüz koruyucu)
        final visorPlate = Path()
          ..moveTo(center.dx - 16, headY - 3.5)
          ..lineTo(center.dx + 16, headY - 3.5)
          ..lineTo(center.dx + 15, headY + 7.5)
          ..lineTo(center.dx, headY + 9.5) // Sivri şövalye çenesi
          ..lineTo(center.dx - 15, headY + 7.5)
          ..close();
        canvas.drawPath(visorPlate, steelMain);

        // Yatay Göz Yarıkları (Dark T-Slit)
        final slitPaint = Paint()..color = const Color(0xFF1A2129)..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 12.5, headY - 2.5, center.dx - 2.5, headY + 1.2),
          const Radius.circular(1),
        ), slitPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx + 2.5, headY - 2.5, center.dx + 12.5, headY + 1.2),
          const Radius.circular(1),
        ), slitPaint);

        // Parlayan Camgöbeği Şövalye Gözleri
        final eyeGlow = Paint()..color = Colors.cyanAccent..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(center.dx - 7.5, headY - 0.7), 1.3, eyeGlow);
        canvas.drawCircle(Offset(center.dx + 7.5, headY - 0.7), 1.3, eyeGlow);
        // Göz ışıltısı (white glint)
        canvas.drawCircle(Offset(center.dx - 7.2, headY - 0.9), 0.5, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(center.dx + 7.8, headY - 0.9), 0.5, Paint()..color = Colors.white);

        // Burun / Siperlik dikey takviye hattı (Merkez omurga)
        final centerRib = Paint()..color = steelLight.color..style = PaintingStyle.stroke..strokeWidth = 1.2;
        canvas.drawLine(Offset(center.dx, headY - 7.5), Offset(center.dx, headY + 9), centerRib);

        // Alt havalandırma delikleri (Breathing holes)
        final ventPaint = Paint()..color = const Color(0xFF263238)..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(center.dx - 5.5, headY + 4.5), 0.9, ventPaint);
        canvas.drawCircle(Offset(center.dx - 8.5, headY + 4.5), 0.9, ventPaint);
        canvas.drawCircle(Offset(center.dx + 5.5, headY + 4.5), 0.9, ventPaint);
        canvas.drawCircle(Offset(center.dx + 8.5, headY + 4.5), 0.9, ventPaint);

        // 4. ŞÖVALYE SORGUCU / MİĞFER TÜYÜ (Red Heroic Plume)
        // Tüy yuvası soketi (Plume holder)
        canvas.drawRect(Rect.fromLTRB(center.dx - 2.5, headY - 20, center.dx + 2.5, headY - 17.5), Paint()..color = Colors.amber.shade700);
        // İhtişamlı Kırmızı Miğfer Tüyü
        final plumePath = Path()
          ..moveTo(center.dx - 2, headY - 20)
          ..quadraticBezierTo(center.dx - 4, headY - 26, center.dx + 1, headY - 29)
          ..quadraticBezierTo(center.dx + 6, headY - 25, center.dx + 2, headY - 20)
          ..close();
        canvas.drawPath(plumePath, Paint()..color = const Color(0xFFD32F2F));
        // Tüy parlama hattı
        final plumeHighlight = Path()
          ..moveTo(center.dx - 0.5, headY - 20)
          ..quadraticBezierTo(center.dx - 2, headY - 25, center.dx + 1, headY - 28)
          ..lineTo(center.dx + 0.5, headY - 20)
          ..close();
        canvas.drawPath(plumeHighlight, Paint()..color = const Color(0xFFFF5252));
      } else if (hatId == 'mage_hat') {
        // Büyücü Şapkası: Görkemli kadife indigo büyücü külahı, hilal ay broşu ve parıldayan mana kristali
        final velvetDeep = Paint()..color = const Color(0xFF251752)..style = PaintingStyle.fill;
        final velvetMain = Paint()..color = const Color(0xFF38237A)..style = PaintingStyle.fill;
        final velvetLight = Paint()..color = const Color(0xFF4F34A8)..style = PaintingStyle.fill;

        // 1. KÜLAH GÖVDESİ (Kafayı tamamen kapatan ve saçla bütünleşen geniş hacimli sihirli külah)
        // Taban: center.dx - 17 ile center.dx + 17 arası. Kafanın tepe dairesi (headY - 16) tamamen külahın içinde kalır!
        final conePath = Path()
          ..moveTo(center.dx - 17, headY - 7.5)
          // Sol kavis: Kafanın sol kenarını (center.dx - 14) genişçe sararak yukarı çıkar
          ..quadraticBezierTo(center.dx - 15, headY - 18, center.dx - 7, headY - 26)
          // Külahın sağa doğru kıvrılan sihirli eğimli ucu
          ..quadraticBezierTo(center.dx + 4, headY - 31, center.dx + 15, headY - 32)
          // Ucun aşağıya doğru bükülen sevimli kıvrımı
          ..quadraticBezierTo(center.dx + 18, headY - 30, center.dx + 17, headY - 27)
          // Sağ dış kavis: Genişleyerek tabana iner
          ..quadraticBezierTo(center.dx + 12, headY - 18, center.dx + 17, headY - 7.5)
          ..close();
        canvas.drawPath(conePath, velvetMain);

        // Külah Sol Işık & Hacim Katmanı (3D Velvet Highlight)
        final coneHighlight = Path()
          ..moveTo(center.dx - 16, headY - 7.5)
          ..quadraticBezierTo(center.dx - 14, headY - 17, center.dx - 6, headY - 25)
          ..lineTo(center.dx + 8, headY - 29)
          ..quadraticBezierTo(center.dx - 2, headY - 18, center.dx - 5, headY - 7.5)
          ..close();
        canvas.drawPath(coneHighlight, velvetLight);

        // Külah Katlanma ve Kumaş Kıvrım Çizgileri
        final foldPaint = Paint()
          ..color = velvetDeep.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        // Alt katlanma çizgisi
        final fold1 = Path()
          ..moveTo(center.dx - 12, headY - 15)
          ..quadraticBezierTo(center.dx, headY - 13, center.dx + 13, headY - 17);
        canvas.drawPath(fold1, foldPaint);
        // Üst katlanma çizgisi
        final fold2 = Path()
          ..moveTo(center.dx - 6, headY - 22)
          ..quadraticBezierTo(center.dx + 5, headY - 23, center.dx + 14, headY - 25);
        canvas.drawPath(fold2, foldPaint);

        // Külah ucundan sarkan altın yıldız sarkıtı (Star pendant)
        canvas.drawLine(
          Offset(center.dx + 17, headY - 27),
          Offset(center.dx + 18, headY - 25),
          Paint()..color = const Color(0xFFFFD54F)..strokeWidth = 0.8,
        );
        final starPaint = Paint()..color = const Color(0xFFFFD54F)..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(center.dx + 18, headY - 24.5), 1.6, starPaint);
        canvas.drawCircle(Offset(center.dx + 18, headY - 24.5), 0.7, Paint()..color = Colors.white);

        // Külah kumaşı üzerindeki altın yıldız işlemeleri (Embroidered stars)
        final goldSparkle = Paint()..color = const Color(0xFFFFE082)..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(center.dx - 9, headY - 19), 0.9, goldSparkle);
        canvas.drawCircle(Offset(center.dx + 6, headY - 20), 0.8, goldSparkle);
        canvas.drawCircle(Offset(center.dx + 2, headY - 26), 0.7, goldSparkle);

        // 2. GENİŞ VE DALGALI SİHİRBAZ SİPERLİĞİ (Floppy Arcane Brim)
        final brimPath = Path()
          ..moveTo(center.dx - 27, headY - 9.5)
          ..quadraticBezierTo(center.dx - 14, headY - 5, center.dx, headY - 6.5)
          ..quadraticBezierTo(center.dx + 14, headY - 5, center.dx + 27, headY - 9.5)
          ..quadraticBezierTo(center.dx + 15, headY - 12, center.dx, headY - 10.5)
          ..quadraticBezierTo(center.dx - 15, headY - 12, center.dx - 27, headY - 9.5)
          ..close();
        canvas.drawPath(brimPath, velvetMain);
        // Siperlik ışıltılı kenar bordürü
        final brimBorder = Paint()
          ..color = const Color(0xFF6B48D1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9;
        canvas.drawPath(brimPath, brimBorder);

        // 3. ALTIN İPEK KUŞAK & HİLAL AY BROŞU
        final sashPath = Path()
          ..moveTo(center.dx - 16.5, headY - 7.5)
          ..lineTo(center.dx + 16.5, headY - 7.5)
          ..lineTo(center.dx + 15, headY - 11)
          ..lineTo(center.dx - 15, headY - 11)
          ..close();
        canvas.drawPath(sashPath, Paint()..color = const Color(0xFFFFB300));
        // Kuşak altın ışıltı bordürü
        canvas.drawLine(
          Offset(center.dx - 15, headY - 11),
          Offset(center.dx + 15, headY - 11),
          Paint()..color = const Color(0xFFFFE082)..strokeWidth = 0.8..style = PaintingStyle.stroke,
        );

        // Merkezdeki Altın Hilal Ay (Golden Crescent Moon Brooch)
        final moonPath = Path()
          ..moveTo(center.dx - 1.5, headY - 12.5)
          ..arcToPoint(
            Offset(center.dx - 1.5, headY - 5.5),
            radius: const Radius.circular(3.5),
            clockwise: false,
          )
          ..arcToPoint(
            Offset(center.dx - 1.5, headY - 12.5),
            radius: const Radius.circular(2.6),
            clockwise: true,
          )
          ..close();
        canvas.drawPath(moonPath, Paint()..color = const Color(0xFFFFD54F));

        // Parlayan Büyü Kristali (Arcane Mana Gem)
        canvas.drawCircle(Offset(center.dx + 0.5, headY - 9), 2.2, Paint()..color = Colors.cyanAccent);
        canvas.drawCircle(Offset(center.dx + 0.5, headY - 9), 1.2, Paint()..color = const Color(0xFFE0F7FA));
        canvas.drawCircle(Offset(center.dx + 0.2, headY - 9.4), 0.6, Paint()..color = Colors.white);
      } else if (hatId == 'ninja_mask') {
        // Ninja Maskesi: Dikişsiz tam siyah shinobi başlığı, odaklanmış anime gözleri ve alın koruyucusu
        final ninjaFabric = Paint()..color = const Color(0xFF1E2124)..style = PaintingStyle.fill;

        // 1. DİKİŞSİZ TEK PARÇA NİNJA BAŞLIĞI VE BOYUN ÖRTÜSÜ (Kafayı ve boynu tek parça kusursuz örter)
        final cowlPath = Path()
          // Kafa üst dairesi
          ..moveTo(center.dx - 16.5, headY)
          ..arcToPoint(
            Offset(center.dx + 16.5, headY),
            radius: const Radius.circular(16.5),
            clockwise: true,
          )
          // Sağ yanak ve boyun hattı (Giysinin yakasına kadar iner)
          ..lineTo(center.dx + 15, headY + 10)
          ..lineTo(center.dx + 9, torsoTop)
          ..lineTo(center.dx - 9, torsoTop)
          ..lineTo(center.dx - 15, headY + 10)
          ..close();
        canvas.drawPath(cowlPath, ninjaFabric);

        // Kafa arkasında rüzgarda dalgalanan kumaş kurdeleler (Shinobi Headband Ribbon Tails)
        final ribbonPath = Path()
          // Üst kurdele
          ..moveTo(center.dx + 14.5, headY - 9.5)
          ..quadraticBezierTo(center.dx + 19, headY - 11.5, center.dx + 25, headY - 7.5)
          ..lineTo(center.dx + 24, headY - 4.5)
          ..quadraticBezierTo(center.dx + 18, headY - 7.5, center.dx + 14.5, headY - 6.5)
          // Alt kurdele
          ..quadraticBezierTo(center.dx + 18, headY - 5.5, center.dx + 22, headY - 1)
          ..lineTo(center.dx + 20, headY + 1.2)
          ..quadraticBezierTo(center.dx + 16, headY - 4, center.dx + 14.5, headY - 5)
          ..close();
        canvas.drawPath(ribbonPath, ninjaFabric);
        canvas.drawPath(ribbonPath, Paint()..color = const Color(0xFF14171A)..style = PaintingStyle.stroke..strokeWidth = 0.7);

        // Çene altı kıvrım gölgesi (Kumaşa 3D derinlik verir)
        final chinFold = Path()
          ..moveTo(center.dx - 8, headY + 12)
          ..quadraticBezierTo(center.dx, headY + 15, center.dx + 8, headY + 12);
        canvas.drawPath(chinFold, Paint()..color = const Color(0xFF14171A)..style = PaintingStyle.stroke..strokeWidth = 1.0);

        // 2. GÖZ YARIK BÖLGESİ (Shinobi Eye Port)
        final eyeSlotRect = Rect.fromLTRB(center.dx - 12, headY - 4.5, center.dx + 12, headY + 2.5);
        canvas.drawRRect(RRect.fromRectAndRadius(eyeSlotRect, const Radius.circular(3)), skinPaint);
        // Maske kenar derinlik gölgesi
        canvas.drawRRect(RRect.fromRectAndRadius(eyeSlotRect, const Radius.circular(3)), Paint()..color = const Color(0x33000000)..style = PaintingStyle.stroke..strokeWidth = 0.8);

        // 3. KARİZMATİK ODAKLANMIŞ NİNJA GÖZLERİ
        // Canlı anime ninja gözleri
        canvas.drawCircle(Offset(center.dx - 5, headY - 0.8), 2.9, eyePaint);
        canvas.drawCircle(Offset(center.dx + 5, headY - 0.8), 2.9, eyePaint);
        // Parlayan beyaz göz ışıltıları (Gözlerin boş/ölü görünmesini engeller!)
        final reflectionPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(center.dx - 6.0, headY - 1.8), 0.9, reflectionPaint);
        canvas.drawCircle(Offset(center.dx + 4.0, headY - 1.8), 0.9, reflectionPaint);

        // Odaklanmış kararlı ninja kaşları (Anime keskin bakış)
        final browPaint = Paint()
          ..color = const Color(0xFF1E2124)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round;
        // Sol kaş (hafif eğimli)
        canvas.drawLine(Offset(center.dx - 8.5, headY - 3.6), Offset(center.dx - 2.5, headY - 2.4), browPaint);
        // Sağ kaş (hafif eğimli)
        canvas.drawLine(Offset(center.dx + 2.5, headY - 2.4), Offset(center.dx + 8.5, headY - 3.6), browPaint);

        // 4. ALIN METAL KORUYUCUSU (Hitai-ate - Shinobi Headband)
        // Kumaş alın bandı
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 14, headY - 12, center.dx + 14, headY - 5),
          const Radius.circular(2),
        ), Paint()..color = const Color(0xFF14171A));

        // Parlak çelik metal levha
        final plateRect = Rect.fromLTRB(center.dx - 10.5, headY - 11, center.dx + 10.5, headY - 6);
        canvas.drawRRect(RRect.fromRectAndRadius(plateRect, const Radius.circular(2)), Paint()..color = const Color(0xFFCFD8DC));
        // Metal levha üst parıltısı
        canvas.drawLine(
          Offset(center.dx - 9.5, headY - 10.2),
          Offset(center.dx + 9.5, headY - 10.2),
          Paint()..color = Colors.white..strokeWidth = 0.8,
        );
        // Levha köşe perçinleri
        final rivetPaint = Paint()..color = const Color(0xFF546E7A)..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(center.dx - 8.8, headY - 9.5), 0.8, rivetPaint);
        canvas.drawCircle(Offset(center.dx - 8.8, headY - 7.5), 0.8, rivetPaint);
        canvas.drawCircle(Offset(center.dx + 8.8, headY - 9.5), 0.8, rivetPaint);
        canvas.drawCircle(Offset(center.dx + 8.8, headY - 7.5), 0.8, rivetPaint);

        // Merkezdeki İşlemeli Ascend Zirve Amblemi (Engraved ninja chevron)
        final emblemPath = Path()
          ..moveTo(center.dx - 3, headY - 7.5)
          ..lineTo(center.dx, headY - 9.6)
          ..lineTo(center.dx + 3, headY - 7.5);
        canvas.drawPath(emblemPath, Paint()..color = const Color(0xFF37474F)..style = PaintingStyle.stroke..strokeWidth = 1.0..strokeCap = StrokeCap.round);
      } else if (hatId == 'crown') {
        // Altın Kral Tacı: İmparatorluk kadife başlığı, oymalı altın taç ve parıldayan yakut/safir mücevherler

        // 1. Kraliyet Kadife Kubbesi (Crown Velvet Cap - Tacın arkasından yükselen lüks kadife kubbe)
        final velvetCap = Path()
          ..moveTo(center.dx - 14, headY - 7)
          ..quadraticBezierTo(center.dx - 13, headY - 21, center.dx, headY - 22)
          ..quadraticBezierTo(center.dx + 13, headY - 21, center.dx + 14, headY - 7)
          ..close();
        canvas.drawPath(velvetCap, Paint()..color = const Color(0xFF880E4F)); // İmparatorluk yakut kırmızısı
        // Kadife ışıltısı
        final velvetLight = Path()
          ..moveTo(center.dx - 9, headY - 7)
          ..quadraticBezierTo(center.dx - 7, headY - 19, center.dx, headY - 20)
          ..quadraticBezierTo(center.dx + 7, headY - 19, center.dx + 9, headY - 7)
          ..close();
        canvas.drawPath(velvetLight, Paint()..color = const Color(0xFFAD1457));

        // 2. Oymalı Altın Taç Gövdesi (3D Sculpted Golden Peaks)
        const goldDeep = Color(0xFFC47F00);
        const goldMain = Color(0xFFFFB300);
        const goldLight = Color(0xFFFFE082);

        final crownPath = Path()
          ..moveTo(center.dx - 15.5, headY - 7)
          ..lineTo(center.dx + 15.5, headY - 7)
          ..lineTo(center.dx + 16, headY - 22)   // Sağ dış uç
          ..lineTo(center.dx + 10, headY - 14)
          ..lineTo(center.dx + 7.5, headY - 26)  // Sağ orta uç
          ..lineTo(center.dx + 1.5, headY - 15)
          ..lineTo(center.dx, headY - 29)        // En yüksek merkez kraliyet ucu
          ..lineTo(center.dx - 1.5, headY - 15)
          ..lineTo(center.dx - 7.5, headY - 26)  // Sol orta uç
          ..lineTo(center.dx - 10, headY - 14)
          ..lineTo(center.dx - 16, headY - 22)   // Sol dış uç
          ..close();
        canvas.drawPath(crownPath, Paint()..color = goldMain);

        // Altın Işık & Pah Katmanı (3D Bevel Highlight)
        final crownHighlight = Path()
          ..moveTo(center.dx - 14, headY - 7)
          ..lineTo(center.dx + 14, headY - 7)
          ..lineTo(center.dx + 14.5, headY - 20)
          ..lineTo(center.dx + 10, headY - 14)
          ..lineTo(center.dx + 7, headY - 24)
          ..lineTo(center.dx + 1.5, headY - 15)
          ..lineTo(center.dx, headY - 27)
          ..lineTo(center.dx - 1.5, headY - 15)
          ..lineTo(center.dx - 7, headY - 24)
          ..lineTo(center.dx - 10, headY - 14)
          ..lineTo(center.dx - 14.5, headY - 20)
          ..close();
        canvas.drawPath(crownHighlight, Paint()..color = goldLight);

        // Taç dış altın kenar konturu
        canvas.drawPath(crownPath, Paint()..color = goldDeep..style = PaintingStyle.stroke..strokeWidth = 1.0);

        // 3. Hermin Kürk Bordürü & İnci Tabanı (Ermine Fur Trim with Royal Pearls)
        // Beyaz hermin kürk bandı
        final furRect = Rect.fromLTRB(center.dx - 15.5, headY - 7.5, center.dx + 15.5, headY - 4.5);
        canvas.drawRRect(RRect.fromRectAndRadius(furRect, const Radius.circular(2)), Paint()..color = const Color(0xFFF8FAFC));
        // Hermin kürk kraliyet siyah benekleri
        final spotPaint = Paint()..color = const Color(0xFF1E293B)..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(center.dx - 10, headY - 6.0), 0.7, spotPaint);
        canvas.drawCircle(Offset(center.dx, headY - 6.0), 0.7, spotPaint);
        canvas.drawCircle(Offset(center.dx + 10, headY - 6.0), 0.7, spotPaint);

        // Altın zemin şeridi ve inciler
        canvas.drawLine(
          Offset(center.dx - 15, headY - 7.5),
          Offset(center.dx + 15, headY - 7.5),
          Paint()..color = goldDeep..strokeWidth = 1.0,
        );

        // 4. Taç Üzerine Monte Edilmiş Değerli Taşlar (Faceted Jewels in Golden Bezels)
        // Merkezdeki Büyük İmparatorluk Yakutu (Oval Royal Ruby)
        canvas.drawCircle(Offset(center.dx, headY - 10.5), 3.2, Paint()..color = goldDeep);
        canvas.drawCircle(Offset(center.dx, headY - 10.5), 2.5, Paint()..color = const Color(0xFFD50000));
        canvas.drawCircle(Offset(center.dx, headY - 10.5), 1.6, Paint()..color = const Color(0xFFFF1744));
        canvas.drawCircle(Offset(center.dx - 0.7, headY - 11.2), 0.7, Paint()..color = Colors.white);

        // Yan Yakut ve Zümrüt Taşlar (Taç gövdesinde)
        canvas.drawCircle(Offset(center.dx - 7, headY - 10), 1.8, Paint()..color = const Color(0xFF1565C0)); // Safir
        canvas.drawCircle(Offset(center.dx - 7, headY - 10), 0.6, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(center.dx + 7, headY - 10), 1.8, Paint()..color = const Color(0xFF00C853)); // Zümrüt
        canvas.drawCircle(Offset(center.dx + 7, headY - 10), 0.6, Paint()..color = Colors.white);

        // 5. Uçlardaki Altın Küreler & Parıltılar (Finials & Sparkle Stars)
        // Merkez uçtaki altın haç/küre
        canvas.drawCircle(Offset(center.dx, headY - 29), 2.2, Paint()..color = goldLight);
        canvas.drawCircle(Offset(center.dx, headY - 29), 1.3, Paint()..color = const Color(0xFFFF1744));
        // Orta uçlar (Safir uçlu altın küreler)
        canvas.drawCircle(Offset(center.dx - 7.5, headY - 26), 1.8, Paint()..color = goldLight);
        canvas.drawCircle(Offset(center.dx - 7.5, headY - 26), 1.0, Paint()..color = const Color(0xFF1565C0));
        canvas.drawCircle(Offset(center.dx + 7.5, headY - 26), 1.8, Paint()..color = goldLight);
        canvas.drawCircle(Offset(center.dx + 7.5, headY - 26), 1.0, Paint()..color = const Color(0xFF00C853));
        // Dış uçlar (Ametist uçlu altın küreler)
        canvas.drawCircle(Offset(center.dx - 16, headY - 22), 1.5, Paint()..color = goldLight);
        canvas.drawCircle(Offset(center.dx - 16, headY - 22), 0.8, Paint()..color = const Color(0xFFAA00FF));
        canvas.drawCircle(Offset(center.dx + 16, headY - 22), 1.5, Paint()..color = goldLight);
        canvas.drawCircle(Offset(center.dx + 16, headY - 22), 0.8, Paint()..color = const Color(0xFFAA00FF));
      } else if (hatId == 'cyber_visor') {
        // Siber Visor: İnce ve zarif cyberpunk HUD akıllı gözlük (Gözleri kapatmaz, şeffaf holografiktir)

        // 1. Minimalist Titanyum Şakak Kolları (Kafanın yanından arkaya uzanan ince kollar)
        final framePaint = Paint()..color = const Color(0xFF263238)..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 16.5, headY - 3.8, center.dx - 13.5, headY - 1.2),
          const Radius.circular(1.0),
        ), framePaint);
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx + 13.5, headY - 3.8, center.dx + 16.5, headY - 1.2),
          const Radius.circular(1.0),
        ), framePaint);
        // Şakak mikro telemetri LED ışığı (Turkuaz parıltı)
        canvas.drawCircle(Offset(center.dx - 15, headY - 2.5), 0.8, Paint()..color = const Color(0xFF00E5FF));

        // 2. Aerodinamik Keskin Cyber Lens Formu (İnce, zarif ve gözün üstünü örten fütüristik hat)
        final lensPath = Path()
          // Üst kaş hattı
          ..moveTo(center.dx - 14.5, headY - 4.2)
          ..lineTo(center.dx + 14.5, headY - 4.2)
          // Sağ dış açılı köşe
          ..lineTo(center.dx + 15, headY - 1.5)
          // Sağ alt aerodinamik kesim
          ..lineTo(center.dx + 13.5, headY + 1.2)
          ..lineTo(center.dx + 3.5, headY + 1.2)
          // Burun köprüsü çentiği
          ..quadraticBezierTo(center.dx, headY + 0.3, center.dx - 3.5, headY + 1.2)
          // Sol alt aerodinamik kesim
          ..lineTo(center.dx - 13.5, headY + 1.2)
          // Sol dış açılı köşe
          ..lineTo(center.dx - 15, headY - 1.5)
          ..close();

        // 3. Yarı Şeffaf Holografik Cam (Karakterin canlı anime gözleri camın arkasından NET şekilde görünür!)
        final holoGlass = Paint()..color = const Color(0x4D00E5FF)..style = PaintingStyle.fill;
        canvas.drawPath(lensPath, holoGlass);

        // Parlayan Elektrik Camgöbeği Neon Kenarlık
        final neonBorder = Paint()
          ..color = const Color(0xFF18FFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9;
        canvas.drawPath(lensPath, neonBorder);

        // 4. Üst Parlama Çizgisi (Glossy Specular Glint)
        canvas.drawLine(
          Offset(center.dx - 12, headY - 3.4),
          Offset(center.dx + 5, headY - 3.4),
          Paint()..color = Colors.white.withValues(alpha: 0.65)..strokeWidth = 0.8,
        );

        // 5. Taktik HUD Hologram Grafikleri (Gözün üzerinde ince fütüristik arayüz)
        // Sağ göz üzerinde holografik dijital hedefleme retikülü ([ + ])
        final hudPaint = Paint()
          ..color = const Color(0xCCFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6;
        canvas.drawCircle(Offset(center.dx + 5, headY - 0.8), 1.6, hudPaint);
        canvas.drawCircle(Offset(center.dx + 5, headY - 0.8), 0.5, Paint()..color = Colors.white..style = PaintingStyle.fill);

        // Sol göz üzerinde mini ses/enerji telemetri çubukları
        final tickPaint = Paint()..color = const Color(0xCC00E5FF)..strokeWidth = 0.7;
        canvas.drawLine(Offset(center.dx - 10, headY - 1.8), Offset(center.dx - 10, headY + 0.2), tickPaint);
        canvas.drawLine(Offset(center.dx - 8.5, headY - 2.4), Offset(center.dx - 8.5, headY + 0.2), tickPaint);
        canvas.drawLine(Offset(center.dx - 7, headY - 1.2), Offset(center.dx - 7, headY + 0.2), tickPaint);
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

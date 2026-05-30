import 'dart:math';
import 'package:flutter/material.dart';
import '../data/loot_pool.dart';

class CharacterAvatar extends StatefulWidget {
  final Map<String, String> equippedItems;
  final double size;
  const CharacterAvatar({
    super.key,
    required this.equippedItems,
    this.size = 150,
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
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
    final center = Offset(size.width / 2, size.height / 2);
    
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

    // Sol Bacak
    final leftLegPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(center.dx - 12, center.dy + 15, center.dx - 4, center.dy + 50),
        const Radius.circular(4),
      ));
    // Sağ Bacak
    final rightLegPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(center.dx + 4, center.dy + 15, center.dx + 12, center.dy + 50),
        const Radius.circular(4),
      ));
    
    canvas.drawPath(leftLegPath, skinPaint);
    canvas.drawPath(rightLegPath, skinPaint);

    // Pantolon Çizimi (Kuşanıldıysa bacakları kaplar)
    final pantsPaint = Paint()
      ..color = pantsColor
      ..style = PaintingStyle.fill;

    if (pantsId.isNotEmpty) {
      if (pantsId == 'shorts') {
        // Kısa şort
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 13, center.dy + 12, center.dx - 3, center.dy + 30),
          const Radius.circular(3),
        ), pantsPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx + 3, center.dy + 12, center.dx + 13, center.dy + 30),
          const Radius.circular(3),
        ), pantsPaint);
      } else if (pantsId == 'ronin_hakama') {
        // Geniş hakama pantolon
        final hakamaPath = Path()
          ..moveTo(center.dx - 16, center.dy + 10)
          ..lineTo(center.dx + 16, center.dy + 10)
          ..lineTo(center.dx + 18, center.dy + 46)
          ..lineTo(center.dx + 2, center.dy + 46)
          ..lineTo(center.dx, center.dy + 20)
          ..lineTo(center.dx - 2, center.dy + 46)
          ..lineTo(center.dx - 18, center.dy + 46)
          ..close();
        canvas.drawPath(hakamaPath, pantsPaint);
      } else {
        // Uzun pantolon
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 13, center.dy + 10, center.dx - 3, center.dy + 48),
          const Radius.circular(4),
        ), pantsPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx + 3, center.dy + 10, center.dx + 13, center.dy + 48),
          const Radius.circular(4),
        ), pantsPaint);
        
        // Zırh parçaları (Çelik/Deri dizlik)
        if (pantsId == 'steel_greaves') {
          final steelPaint = Paint()..color = Colors.blueGrey.shade300..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(center.dx - 8, center.dy + 28), 5, steelPaint);
          canvas.drawCircle(Offset(center.dx + 8, center.dy + 28), 5, steelPaint);
        } else if (pantsId == 'leather_greaves') {
          final leatherPaint = Paint()..color = Colors.brown.shade800..style = PaintingStyle.fill;
          canvas.drawRect(Rect.fromLTWH(center.dx - 11, center.dy + 24, 6, 8), leatherPaint);
          canvas.drawRect(Rect.fromLTWH(center.dx + 5, center.dy + 24, 6, 8), leatherPaint);
        } else if (pantsId == 'cyber_pants') {
          // Neon çizgiler
          final neonPaint = Paint()..color = Colors.cyanAccent..style = PaintingStyle.stroke..strokeWidth = 1.5;
          canvas.drawLine(Offset(center.dx - 8, center.dy + 15), Offset(center.dx - 8, center.dy + 40), neonPaint);
          canvas.drawLine(Offset(center.dx + 8, center.dy + 15), Offset(center.dx + 8, center.dy + 40), neonPaint);
        }
      }
    } else {
      // Temel gri şort (Kıyafet kuşanılmamışsa)
      final defaultShortsPaint = Paint()..color = Colors.blueGrey.shade800..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTRB(center.dx - 13, center.dy + 12, center.dx + 13, center.dy + 22), defaultShortsPaint);
    }

    // --- 2. GÖVDE & KOLLAR (Nefes alma animasyonu ile dikey esner) ---
    final torsoItem = LootPool.getItemById(equippedItems['torso'] ?? '');
    final Color torsoColor = torsoItem?.color ?? Colors.grey.shade800;
    final String torsoId = torsoItem?.id ?? '';

    final double torsoTop = center.dy - 25 + breath;
    final double torsoBottom = center.dy + 14 + breath;

    // Kollar (Ten)
    final leftArmPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(center.dx - 22, torsoTop + 6, center.dx - 14, torsoBottom - 2),
        const Radius.circular(4),
      ));
    final rightArmPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(center.dx + 14, torsoTop + 6, center.dx + 22, torsoBottom - 2),
        const Radius.circular(4),
      ));
    canvas.drawPath(leftArmPath, skinPaint);
    canvas.drawPath(rightArmPath, skinPaint);

    // Gövde (Ten)
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(center.dx - 14, torsoTop, center.dx + 14, torsoBottom),
      const Radius.circular(6),
    ), skinPaint);

    // Kıyafet Çizimi
    final torsoPaint = Paint()
      ..color = torsoColor
      ..style = PaintingStyle.fill;

    if (torsoId.isNotEmpty) {
      if (torsoId == 'tshirt') {
        // Düz Tişört
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 15, torsoTop - 1, center.dx + 15, torsoBottom),
          const Radius.circular(5),
        ), torsoPaint);
        // Kısa kollar
        canvas.drawRect(Rect.fromLTRB(center.dx - 21, torsoTop + 3, center.dx - 14, torsoTop + 14), torsoPaint);
        canvas.drawRect(Rect.fromLTRB(center.dx + 14, torsoTop + 3, center.dx + 21, torsoTop + 14), torsoPaint);
      } else if (torsoId == 'tunic') {
        // Tunik
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 15, torsoTop - 1, center.dx + 15, torsoBottom + 4),
          const Radius.circular(4),
        ), torsoPaint);
        // Kemer
        final beltPaint = Paint()..color = Colors.black87..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTRB(center.dx - 15, torsoBottom - 4, center.dx + 15, torsoBottom), beltPaint);
      } else if (torsoId == 'hoodie') {
        // Hoodie
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 16, torsoTop - 2, center.dx + 16, torsoBottom),
          const Radius.circular(6),
        ), torsoPaint);
        // Uzun kollar
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 22, torsoTop + 2, center.dx - 14, torsoBottom - 4),
          const Radius.circular(3),
        ), torsoPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx + 14, torsoTop + 2, center.dx + 22, torsoBottom - 4),
          const Radius.circular(3),
        ), torsoPaint);
        // Kapüşon arkası
        final hoodPaint = Paint()..color = torsoColor.withValues(alpha: 0.8)..style = PaintingStyle.fill;
        canvas.drawOval(Rect.fromLTRB(center.dx - 12, torsoTop - 8, center.dx + 12, torsoTop + 4), hoodPaint);
      } else if (torsoId == 'leather_armor') {
        // Deri Zırh
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 15, torsoTop - 1, center.dx + 15, torsoBottom),
          const Radius.circular(5),
        ), torsoPaint);
        // Deri kayışlar
        final strapPaint = Paint()..color = Colors.brown.shade900..style = PaintingStyle.stroke..strokeWidth = 2;
        canvas.drawLine(Offset(center.dx - 14, torsoTop + 4), Offset(center.dx + 14, torsoTop + 14), strapPaint);
        canvas.drawLine(Offset(center.dx + 14, torsoTop + 4), Offset(center.dx - 14, torsoTop + 14), strapPaint);
      } else if (torsoId == 'suit_jacket') {
        // Takım Elbise Ceketi
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 16, torsoTop - 1, center.dx + 16, torsoBottom),
          const Radius.circular(4),
        ), torsoPaint);
        // Beyaz gömlek V-neck
        final shirtPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
        final shirtPath = Path()
          ..moveTo(center.dx - 5, torsoTop - 1)
          ..lineTo(center.dx + 5, torsoTop - 1)
          ..lineTo(center.dx, torsoTop + 8)
          ..close();
        canvas.drawPath(shirtPath, shirtPaint);
        // Kırmızı kravat
        final tiePaint = Paint()..color = Colors.red..style = PaintingStyle.fill;
        final tiePath = Path()
          ..moveTo(center.dx - 1, torsoTop + 1)
          ..lineTo(center.dx + 1, torsoTop + 1)
          ..lineTo(center.dx + 2, torsoTop + 12)
          ..lineTo(center.dx, torsoTop + 15)
          ..lineTo(center.dx - 2, torsoTop + 12)
          ..close();
        canvas.drawPath(tiePath, tiePaint);
      } else if (torsoId == 'steel_chestplate') {
        // Çelik Zırh
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 16, torsoTop - 2, center.dx + 16, torsoBottom + 1),
          const Radius.circular(6),
        ), torsoPaint);
        // Metal parıltısı ve omuzluklar
        final detailPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1;
        canvas.drawLine(Offset(center.dx - 8, torsoTop + 6), Offset(center.dx - 8, torsoBottom - 6), detailPaint);
        canvas.drawCircle(Offset(center.dx - 12, torsoTop + 4), 3, detailPaint);
        canvas.drawCircle(Offset(center.dx + 12, torsoTop + 4), 3, detailPaint);
      } else if (torsoId == 'mage_robe') {
        // Büyücü Cübbesi
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 15, torsoTop - 2, center.dx + 15, torsoBottom + 12),
          const Radius.circular(5),
        ), torsoPaint);
        // Altın detaylar/kenarlıklar
        final goldDetail = Paint()..color = Colors.amberAccent..style = PaintingStyle.stroke..strokeWidth = 1.5;
        canvas.drawLine(Offset(center.dx, torsoTop - 2), Offset(center.dx, torsoBottom + 12), goldDetail);
        canvas.drawRect(Rect.fromLTRB(center.dx - 15, torsoBottom + 10, center.dx + 15, torsoBottom + 12), Paint()..color = Colors.amberAccent);
      } else if (torsoId == 'assassin_cloak') {
        // Suikastçı Pelerini
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 17, torsoTop - 3, center.dx + 17, torsoBottom + 8),
          const Radius.circular(6),
        ), torsoPaint);
        // Pelerin bağcığı / Omuz korumalıkları
        final padPaint = Paint()..color = Colors.black..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTRB(center.dx - 18, torsoTop - 3, center.dx - 10, torsoTop + 3), padPaint);
        canvas.drawRect(Rect.fromLTRB(center.dx + 10, torsoTop - 3, center.dx + 18, torsoTop + 3), padPaint);
      } else if (torsoId == 'paladin_armor') {
        // Kutsal Işık Zırhı
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 16, torsoTop - 3, center.dx + 16, torsoBottom + 2),
          const Radius.circular(6),
        ), torsoPaint);
        // Ortasında parlayan mavi/kırmızı taş
        final gemPaint = Paint()..color = Colors.cyanAccent..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(center.dx, torsoTop + 8), 4, gemPaint);
      } else if (torsoId == 'cyber_suit') {
        // Siber Zırh
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 16, torsoTop - 2, center.dx + 16, torsoBottom),
          const Radius.circular(5),
        ), torsoPaint);
        // Siber parlayan hatlar
        final gridPaint = Paint()..color = Colors.cyanAccent..style = PaintingStyle.stroke..strokeWidth = 1.2;
        canvas.drawLine(Offset(center.dx - 10, torsoTop + 6), Offset(center.dx + 10, torsoTop + 6), gridPaint);
        canvas.drawLine(Offset(center.dx - 6, torsoTop + 12), Offset(center.dx + 6, torsoTop + 12), gridPaint);
      }
    } else {
      // Temel tişört (Giysi kuşanılmamışsa)
      final defaultTshirtPaint = Paint()..color = Colors.grey.shade700..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(center.dx - 14, torsoTop, center.dx + 14, torsoBottom),
        const Radius.circular(5),
      ), defaultTshirtPaint);
    }

    // --- 3. BOYUN & KAFA (Ten, boyun ve kafa nefes almaya göre dikey kayar) ---
    final double headY = center.dy - 43 + breath;
    final double neckTop = center.dy - 30 + breath;

    // Boyun
    canvas.drawRect(Rect.fromLTRB(center.dx - 4, neckTop, center.dx + 4, torsoTop + 1), skinPaint);

    // Kafa
    canvas.drawCircle(Offset(center.dx, headY), 16, skinPaint);

    // Gözler
    canvas.drawCircle(Offset(center.dx - 5, headY - 1), 2, eyePaint);
    canvas.drawCircle(Offset(center.dx + 5, headY - 1), 2, eyePaint);

    // Yanaklar / Kızarıklıklar
    final blushPaint = Paint()..color = Colors.pinkAccent.withValues(alpha: 0.35)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx - 9, headY + 3), 2.5, blushPaint);
    canvas.drawCircle(Offset(center.dx + 9, headY + 3), 2.5, blushPaint);

    // --- 4. ŞAPKA ---
    final hatItem = LootPool.getItemById(equippedItems['hat'] ?? '');
    final Color hatColor = hatItem?.color ?? Colors.transparent;
    final String hatId = hatItem?.id ?? '';

    if (hatId.isNotEmpty) {
      final hatPaint = Paint()..color = hatColor..style = PaintingStyle.fill;

      if (hatId == 'straw_hat') {
        // Hasır Şapka
        // Brim (Oval kenarlık)
        canvas.drawOval(Rect.fromLTRB(center.dx - 26, headY - 14, center.dx + 26, headY - 6), hatPaint);
        // Dome (Tepe)
        canvas.drawArc(
          Rect.fromLTRB(center.dx - 12, headY - 26, center.dx + 12, headY - 10),
          pi, pi, true, hatPaint
        );
        // Kahverengi kurdele
        canvas.drawRect(
          Rect.fromLTRB(center.dx - 12, headY - 14, center.dx + 12, headY - 11),
          Paint()..color = Colors.brown.shade800
        );
      } else if (hatId == 'bandana') {
        // Bandana
        canvas.drawRect(Rect.fromLTRB(center.dx - 15, headY - 15, center.dx + 15, headY - 9), hatPaint);
        // Düğüm arkada
        canvas.drawCircle(Offset(center.dx - 16, headY - 12), 3, hatPaint);
      } else if (hatId == 'cap') {
        // Kep şapka
        canvas.drawArc(
          Rect.fromLTRB(center.dx - 14, headY - 23, center.dx + 14, headY - 10),
          pi, pi, true, hatPaint
        );
        // Siperlik
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx + 4, headY - 15, center.dx + 24, headY - 11),
          const Radius.circular(2),
        ), hatPaint);
      } else if (hatId == 'beanie') {
        // Bere
        canvas.drawArc(
          Rect.fromLTRB(center.dx - 15, headY - 25, center.dx + 15, headY - 9),
          pi, pi, true, hatPaint
        );
        // Pom-pom
        canvas.drawCircle(Offset(center.dx, headY - 26), 4, Paint()..color = Colors.white);
      } else if (hatId == 'cowboy_hat') {
        // Kovboy şapkası
        final path = Path()
          ..moveTo(center.dx - 24, headY - 10)
          ..quadraticBezierTo(center.dx, headY - 16, center.dx + 24, headY - 10)
          ..lineTo(center.dx + 14, headY - 14)
          ..quadraticBezierTo(center.dx, headY - 30, center.dx - 14, headY - 14)
          ..close();
        canvas.drawPath(path, hatPaint);
      } else if (hatId == 'iron_helmet') {
        // Şövalye Miğferi
        canvas.drawArc(
          Rect.fromLTRB(center.dx - 16, headY - 24, center.dx + 16, headY - 8),
          pi, pi, true, hatPaint
        );
        canvas.drawRect(Rect.fromLTRB(center.dx - 16, headY - 8, center.dx + 16, headY), hatPaint);
        // Visor yarığı
        canvas.drawRect(Rect.fromLTRB(center.dx - 10, headY - 12, center.dx + 10, headY - 9), eyePaint);
      } else if (hatId == 'mage_hat') {
        // Büyücü Şapkası
        // Geniş brim
        canvas.drawOval(Rect.fromLTRB(center.dx - 22, headY - 15, center.dx + 22, headY - 8), hatPaint);
        // Yüksek koni
        final conePath = Path()
          ..moveTo(center.dx - 12, headY - 12)
          ..lineTo(center.dx + 12, headY - 12)
          ..quadraticBezierTo(center.dx - 2, headY - 32, center.dx - 8, headY - 45)
          ..quadraticBezierTo(center.dx - 4, headY - 32, center.dx - 12, headY - 12)
          ..close();
        canvas.drawPath(conePath, hatPaint);
      } else if (hatId == 'ninja_mask') {
        // Ninja Maskesi (Kafayı tamamen sarar, gözler hariç)
        canvas.drawCircle(Offset(center.dx, headY), 16, hatPaint);
        // Gözlerin olduğu alan için ten rengi bir yarık açıyoruz
        final slitPaint = Paint()..color = const Color(0xFFFFD1A9)..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 9, headY - 4, center.dx + 9, headY + 2),
          const Radius.circular(3),
        ), slitPaint);
        canvas.drawCircle(Offset(center.dx - 4, headY - 1), 1.5, eyePaint);
        canvas.drawCircle(Offset(center.dx + 4, headY - 1), 1.5, eyePaint);
      } else if (hatId == 'crown') {
        // Altın Tac
        final crownPath = Path()
          ..moveTo(center.dx - 14, headY - 10)
          ..lineTo(center.dx + 14, headY - 10)
          ..lineTo(center.dx + 16, headY - 26) // Sağ uç
          ..lineTo(center.dx + 8, headY - 18)
          ..lineTo(center.dx, headY - 30) // Orta uç
          ..lineTo(center.dx - 8, headY - 18)
          ..lineTo(center.dx - 16, headY - 26) // Sol uç
          ..close();
        canvas.drawPath(crownPath, hatPaint);
        
        // Taç üzerindeki mücevherler (Küçük renkli daireler)
        canvas.drawCircle(Offset(center.dx - 14, headY - 24), 2, Paint()..color = Colors.red);
        canvas.drawCircle(Offset(center.dx, headY - 28), 2, Paint()..color = Colors.blue);
        canvas.drawCircle(Offset(center.dx + 14, headY - 24), 2, Paint()..color = Colors.green);
      } else if (hatId == 'cyber_visor') {
        // Siber Vizör
        final visorPaint = Paint()..color = Colors.cyanAccent..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(center.dx - 12, headY - 5, center.dx + 12, headY + 1),
          const Radius.circular(2),
        ), visorPaint);
        // Siber parıltı neon çizgisi
        final glowPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;
        canvas.drawLine(Offset(center.dx - 12, headY - 2), Offset(center.dx + 12, headY - 2), glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CharacterPainter oldDelegate) {
    return oldDelegate.equippedItems != equippedItems ||
        oldDelegate.animationValue != animationValue;
  }
}

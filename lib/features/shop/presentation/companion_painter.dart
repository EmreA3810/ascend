import 'dart:math';
import 'package:flutter/material.dart';
import '../data/companion_data.dart';

/// Evcil hayvanları (Companions) karakterle aynı görsel zenginlikte,
/// pikselsel/vektörel RPG tarzında çizen CustomPainter.
class CompanionPainter extends CustomPainter {
  final CompanionModel companion;
  final double animationValue;

  CompanionPainter({
    required this.companion,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // 40x40 birimlik referans koordinat sistemine ölçekle
    final scale = min(size.width / 40.0, size.height / 40.0);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);

    // Animasyon hesapları: süzülme ve nefes alma
    final floatOffset = sin(animationValue * 2 * pi) * 1.6;
    final flap = sin(animationValue * 4 * pi);

    canvas.translate(0, floatOffset);

    // Yer aurası / gölgesi
    final shadowPaint = Paint()
      ..color = companion.primaryColor.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 18), width: 22, height: 7),
      shadowPaint,
    );

    // Hayvan türüne göre özel çizim
    switch (companion.id) {
      case 'archimedes':
        _paintOwl(canvas, flap);
        break;
      case 'kitsune':
        _paintKitsune(canvas, flap);
        break;
      case 'pyror':
        _paintDragon(canvas, flap);
        break;
      case 'umbra':
        _paintShadowCat(canvas, flap);
        break;
      default:
        _paintGenericPet(canvas, flap);
        break;
    }

    canvas.restore();
  }

  // ==========================================
  // 1. ARCHIMEDES (Bilge Baykuş)
  // ==========================================
  void _paintOwl(Canvas canvas, double flap) {
    final bodyPaint = Paint()..color = const Color(0xFF4F46E5); // Koyu indigo
    final bellyPaint = Paint()..color = const Color(0xFFA5B4FC); // Açık göbek
    final earPaint = Paint()..color = const Color(0xFF3730A3);
    final eyeWhite = Paint()..color = Colors.white;
    final eyeIris = Paint()..color = const Color(0xFFF59E0B); // Kehribar/altın göz
    final pupil = Paint()..color = const Color(0xFF1E1B4B);
    final beakPaint = Paint()..color = const Color(0xFFF97316); // Turuncu gaga
    final hatPaint = Paint()..color = const Color(0xFF1E1B4B); // Büyücü/Mezuniyet şapkası
    final goldTrim = Paint()..color = const Color(0xFFFBBF24);

    // Kulak tüyleri
    final leftEar = Path()
      ..moveTo(-10, -12)
      ..lineTo(-14, -20)
      ..lineTo(-6, -15)
      ..close();
    final rightEar = Path()
      ..moveTo(10, -12)
      ..lineTo(14, -20)
      ..lineTo(6, -15)
      ..close();
    canvas.drawPath(leftEar, earPaint);
    canvas.drawPath(rightEar, earPaint);

    // Kanatlar (Flapping animation)
    final wingYOffset = flap * 2.0;
    final leftWing = Path()
      ..moveTo(-12, -2)
      ..quadraticBezierTo(-19 - flap, 4 + wingYOffset, -14, 12)
      ..quadraticBezierTo(-10, 6, -10, 0)
      ..close();
    final rightWing = Path()
      ..moveTo(12, -2)
      ..quadraticBezierTo(19 + flap, 4 + wingYOffset, 14, 12)
      ..quadraticBezierTo(10, 6, 10, 0)
      ..close();
    canvas.drawPath(leftWing, earPaint);
    canvas.drawPath(rightWing, earPaint);

    // Ana gövde (Tombul baykuş silueti)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 0), width: 22, height: 26),
        const Radius.circular(10),
      ),
      bodyPaint,
    );

    // Göbek tüyleri
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 4), width: 14, height: 16),
        const Radius.circular(7),
      ),
      bellyPaint,
    );

    // Göğüs tüy desenleri
    final featherLine = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(-4, 2), const Offset(-1, 5), featherLine);
    canvas.drawLine(const Offset(4, 2), const Offset(1, 5), featherLine);
    canvas.drawLine(const Offset(-3, 7), const Offset(0, 10), featherLine);

    // Kocaman sevimli baykuş gözleri
    canvas.drawCircle(const Offset(-5, -4), 4.8, eyeWhite);
    canvas.drawCircle(const Offset(5, -4), 4.8, eyeWhite);
    canvas.drawCircle(const Offset(-5, -4), 3.2, eyeIris);
    canvas.drawCircle(const Offset(5, -4), 3.2, eyeIris);
    canvas.drawCircle(const Offset(-5, -4), 1.8, pupil);
    canvas.drawCircle(const Offset(5, -4), 1.8, pupil);
    // Göz parıltısı
    canvas.drawCircle(const Offset(-6, -5), 0.9, eyeWhite);
    canvas.drawCircle(const Offset(4, -5), 0.9, eyeWhite);

    // Küçük sevimli gaga
    final beak = Path()
      ..moveTo(0, -2)
      ..lineTo(-2.5, 1)
      ..lineTo(2.5, 1)
      ..close();
    canvas.drawPath(beak, beakPaint);

    // Minik ayaklar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(-4, 13), width: 4, height: 3),
        const Radius.circular(2),
      ),
      beakPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(4, 13), width: 4, height: 3),
        const Radius.circular(2),
      ),
      beakPaint,
    );

    // Başındaki Bilge Şapkası (Mortarboard / Scholar hat)
    final hatDiamond = Path()
      ..moveTo(0, -18)
      ..lineTo(12, -15)
      ..lineTo(0, -12)
      ..lineTo(-12, -15)
      ..close();
    canvas.drawPath(hatDiamond, hatPaint);
    canvas.drawCircle(const Offset(0, -15), 1.2, goldTrim);
    // Püskül
    final tassel = Path()
      ..moveTo(0, -15)
      ..lineTo(8, -13)
      ..lineTo(9, -8);
    final tasselPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(tassel, tasselPaint);
  }

  // ==========================================
  // 2. KITSUNE (Siber Neon Tilki)
  // ==========================================
  void _paintKitsune(Canvas canvas, double flap) {
    final furMain = Paint()..color = const Color(0xFF06B6D4); // Neon Cyan
    final furLight = Paint()..color = const Color(0xFFE0F2FE); // Buz mavisi / beyaz göğüs
    final earInner = Paint()..color = const Color(0xFF0891B2);
    final eyePaint = Paint()..color = const Color(0xFF67E8F9); // Parlayan neon göz
    final eyePupil = Paint()..color = const Color(0xFF083344);
    final nosePaint = Paint()..color = const Color(0xFF0F172A);
    final cyberGlow = Paint()
      ..color = const Color(0xFF22D3EE).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Kuyruklar (Dalgalanan kabarık siber tilki kuyruğu)
    final tailWave = flap * 2.5;
    final tailPath = Path()
      ..moveTo(6, 6)
      ..cubicTo(18 + tailWave, 2, 22, -8 - tailWave, 14, -14)
      ..cubicTo(10, -6, 12, 4, 4, 10)
      ..close();
    canvas.drawPath(tailPath, furMain);

    // Kuyruk beyaz ucu
    final tailTip = Path()
      ..moveTo(14, -14)
      ..lineTo(20 + (tailWave * 0.5), -10)
      ..lineTo(16, -6)
      ..close();
    canvas.drawPath(tailTip, furLight);

    // Gövde
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 4), width: 16, height: 18),
        const Radius.circular(8),
      ),
      furMain,
    );

    // Beyaz göğüs kürk
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 6), width: 9, height: 12),
        const Radius.circular(5),
      ),
      furLight,
    );

    // Baş
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -5), width: 18, height: 15),
        const Radius.circular(8),
      ),
      furMain,
    );

    // Sivri tilki kulakları
    final leftEar = Path()
      ..moveTo(-7, -10)
      ..lineTo(-11, -19)
      ..lineTo(-2, -12)
      ..close();
    final rightEar = Path()
      ..moveTo(7, -10)
      ..lineTo(11, -19)
      ..lineTo(2, -12)
      ..close();
    canvas.drawPath(leftEar, furMain);
    canvas.drawPath(rightEar, furMain);
    // İç kulak
    final leftInner = Path()
      ..moveTo(-6, -11)
      ..lineTo(-9, -17)
      ..lineTo(-3, -12)
      ..close();
    final rightInner = Path()
      ..moveTo(6, -11)
      ..lineTo(9, -17)
      ..lineTo(3, -12)
      ..close();
    canvas.drawPath(leftInner, earInner);
    canvas.drawPath(rightInner, earInner);

    // Yanak tüyleri (Sevimli tilki formu)
    final cheekLeft = Path()
      ..moveTo(-8, -4)
      ..lineTo(-12, -2)
      ..lineTo(-7, 1)
      ..close();
    final cheekRight = Path()
      ..moveTo(8, -4)
      ..lineTo(12, -2)
      ..lineTo(7, 1)
      ..close();
    canvas.drawPath(cheekLeft, furLight);
    canvas.drawPath(cheekRight, furLight);

    // Parlayan neon siber gözler
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(-4, -5), width: 4.5, height: 3),
        const Radius.circular(2),
      ),
      eyePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(4, -5), width: 4.5, height: 3),
        const Radius.circular(2),
      ),
      eyePaint,
    );
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(-4, -5), 1.2, eyePupil);
    canvas.drawCircle(const Offset(4, -5), 1.2, eyePupil);
    canvas.drawCircle(const Offset(-5, -6), 0.7, whitePaint);
    canvas.drawCircle(const Offset(3, -6), 0.7, whitePaint);

    // Burun
    canvas.drawCircle(const Offset(0, -1), 1.2, nosePaint);

    // Siber holografik alın çizgisi (Cyber visor efekti)
    canvas.drawLine(const Offset(-4, -9), const Offset(4, -9), cyberGlow);
    canvas.drawCircle(const Offset(0, -9), 1.0, whitePaint);
  }

  // ==========================================
  // 3. PYROR (Yavru Ejderha)
  // ==========================================
  void _paintDragon(Canvas canvas, double flap) {
    final scaleRed = Paint()..color = const Color(0xFFDC2626); // Ateş kırmızısı
    final darkRed = Paint()..color = const Color(0xFF991B1B);
    final bellyOrange = Paint()..color = const Color(0xFFFED7AA); // Şeftali/altın göbek
    final hornGold = Paint()..color = const Color(0xFFF59E0B);
    final wingMembrane = Paint()..color = const Color(0xFFF87171);
    final eyePaint = Paint()..color = const Color(0xFFFDE047); // Sarı ejderha gözü
    final flamePaint = Paint()..color = const Color(0xFFFB923C);

    // Kanatlar (Çırpınan kanatlar)
    final wingAngle = flap * 0.25;
    // Sol kanat
    canvas.save();
    canvas.translate(-8, -4);
    canvas.rotate(-wingAngle);
    final leftWing = Path()
      ..moveTo(0, 0)
      ..lineTo(-14, -10)
      ..quadraticBezierTo(-10, -2, -12, 4)
      ..quadraticBezierTo(-6, 2, 0, 4)
      ..close();
    canvas.drawPath(leftWing, wingMembrane);
    canvas.drawLine(const Offset(0, 0), const Offset(-14, -10), darkRed);
    canvas.restore();

    // Sağ kanat
    canvas.save();
    canvas.translate(8, -4);
    canvas.rotate(wingAngle);
    final rightWing = Path()
      ..moveTo(0, 0)
      ..lineTo(14, -10)
      ..quadraticBezierTo(10, -2, 12, 4)
      ..quadraticBezierTo(6, 2, 0, 4)
      ..close();
    canvas.drawPath(rightWing, wingMembrane);
    canvas.drawLine(const Offset(0, 0), const Offset(14, -10), darkRed);
    canvas.restore();

    // Ejderha Kuyruğu ve ucundaki alev
    final tailPath = Path()
      ..moveTo(4, 8)
      ..cubicTo(12, 10, 14, 16, 16, 12)
      ..cubicTo(14, 8, 8, 4, 2, 6)
      ..close();
    canvas.drawPath(tailPath, scaleRed);
    // Kuyruk alevi
    final flame = Path()
      ..moveTo(16, 12)
      ..quadraticBezierTo(19, 9 + flap, 18, 5)
      ..quadraticBezierTo(15, 8, 16, 12)
      ..close();
    canvas.drawPath(flame, flamePaint);

    // Tombik ejderha gövdesi
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 4), width: 18, height: 18),
        const Radius.circular(8),
      ),
      scaleRed,
    );

    // Göbek pulları
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 5), width: 10, height: 13),
        const Radius.circular(5),
      ),
      bellyOrange,
    );

    // Baş
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -6), width: 20, height: 16),
        const Radius.circular(9),
      ),
      scaleRed,
    );

    // Minik ejderha boynuzları
    final leftHorn = Path()
      ..moveTo(-6, -12)
      ..quadraticBezierTo(-10, -18, -12, -19)
      ..quadraticBezierTo(-8, -15, -3, -13)
      ..close();
    final rightHorn = Path()
      ..moveTo(6, -12)
      ..quadraticBezierTo(10, -18, 12, -19)
      ..quadraticBezierTo(8, -15, 3, -13)
      ..close();
    canvas.drawPath(leftHorn, hornGold);
    canvas.drawPath(rightHorn, hornGold);

    // Ejderha gözleri
    canvas.drawCircle(const Offset(-5, -6), 4.0, eyePaint);
    canvas.drawCircle(const Offset(5, -6), 4.0, eyePaint);
    // Dikey ejderha göz bebeği
    final pupilRect1 = Rect.fromCenter(center: const Offset(-5, -6), width: 2.0, height: 5.5);
    final pupilRect2 = Rect.fromCenter(center: const Offset(5, -6), width: 2.0, height: 5.5);
    canvas.drawOval(pupilRect1, Paint()..color = const Color(0xFF450A0A));
    canvas.drawOval(pupilRect2, Paint()..color = const Color(0xFF450A0A));
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(-6, -7), 0.9, whitePaint);
    canvas.drawCircle(const Offset(4, -7), 0.9, whitePaint);

    // Sevimli burun delikleri (Duman tüten minik burun)
    canvas.drawCircle(const Offset(-2, -1), 0.8, darkRed);
    canvas.drawCircle(const Offset(2, -1), 0.8, darkRed);
  }

  // ==========================================
  // 4. UMBRA (Gölge Kedisi)
  // ==========================================
  void _paintShadowCat(Canvas canvas, double flap) {
    final catBlack = Paint()..color = const Color(0xFF1E1B4B); // Gece mavisi / karanlık mor
    final catInner = Paint()..color = const Color(0xFF4C1D95);
    final eyePurple = Paint()..color = const Color(0xFFA855F7); // Parlayan mor ametist göz
    final eyePupil = Paint()..color = const Color(0xFF0F0728);
    final whiskerPaint = Paint()
      ..color = const Color(0xFFC084FC).withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    // Kıvrık gölge kuyruğu
    final tailWave = flap * 2.0;
    final tailPath = Path()
      ..moveTo(5, 8)
      ..cubicTo(14 + tailWave, 10, 18, 0 - tailWave, 15, -6)
      ..cubicTo(12, 0, 10, 8, 3, 10)
      ..close();
    canvas.drawPath(tailPath, catBlack);

    // Kuyruk ucundaki mistik duman halkası
    canvas.drawCircle(
      Offset(15 + (tailWave * 0.5), -6),
      2.5,
      Paint()
        ..color = const Color(0xFFA855F7).withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Gövde
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 4), width: 17, height: 18),
        const Radius.circular(8),
      ),
      catBlack,
    );

    // Baş (Kedi kafası)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -5), width: 19, height: 15),
        const Radius.circular(8),
      ),
      catBlack,
    );

    // Sivri kedi kulakları
    final leftEar = Path()
      ..moveTo(-7, -10)
      ..lineTo(-10, -18)
      ..lineTo(-2, -12)
      ..close();
    final rightEar = Path()
      ..moveTo(7, -10)
      ..lineTo(10, -18)
      ..lineTo(2, -12)
      ..close();
    canvas.drawPath(leftEar, catBlack);
    canvas.drawPath(rightEar, catBlack);
    // İç pembe/mor kulak
    final leftInner = Path()
      ..moveTo(-6, -11)
      ..lineTo(-8, -16)
      ..lineTo(-3, -12)
      ..close();
    final rightInner = Path()
      ..moveTo(6, -11)
      ..lineTo(8, -16)
      ..lineTo(3, -12)
      ..close();
    canvas.drawPath(leftInner, catInner);
    canvas.drawPath(rightInner, catInner);

    // Parlayan ametist kedi gözleri
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-4.5, -5), width: 4.8, height: 3.5),
      eyePurple,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(4.5, -5), width: 4.8, height: 3.5),
      eyePurple,
    );
    // Gözbebeği
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-4.5, -5), width: 1.8, height: 3.2),
      eyePupil,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(4.5, -5), width: 1.8, height: 3.2),
      eyePupil,
    );
    // Parlama
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(-5.2, -6), 0.8, whitePaint);
    canvas.drawCircle(const Offset(3.8, -6), 0.8, whitePaint);

    // Minik kedi burnu & ağzı
    canvas.drawCircle(const Offset(0, -1), 1.0, Paint()..color = const Color(0xFFC084FC));

    // Bıyıklar
    canvas.drawLine(const Offset(-7, -1), const Offset(-13, -3), whiskerPaint);
    canvas.drawLine(const Offset(-7, 1), const Offset(-13, 2), whiskerPaint);
    canvas.drawLine(const Offset(7, -1), const Offset(13, -3), whiskerPaint);
    canvas.drawLine(const Offset(7, 1), const Offset(13, 2), whiskerPaint);
  }

  void _paintGenericPet(Canvas canvas, double flap) {
    final petPaint = Paint()..color = companion.primaryColor;
    canvas.drawCircle(const Offset(0, 0), 12, petPaint);
    canvas.drawCircle(const Offset(-4, -2), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(4, -2), 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CompanionPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.companion.id != companion.id;
  }
}

import 'dart:math';
import 'package:flutter/material.dart';

class _Particle {
  double x;
  double y;
  double speed;
  double size;
  double opacity;
  double phase;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.phase,
  });
}

/// Zen Modu için seçili müziğe göre dinamik ve pürüzsüz arka plan partikül animasyonu.
/// Düşük güç tüketimi için maksimum 25 parçacıkla sınırlandırılmış ve RepaintBoundary ile sarılmıştır.
class ZenParticlesWidget extends StatefulWidget {
  final String? trackType; // 'synth_rain', 'synth_lofi', 'synth_zen', 'synth_breeze'
  const ZenParticlesWidget({super.key, this.trackType});

  @override
  State<ZenParticlesWidget> createState() => _ZenParticlesWidgetState();
}

class _ZenParticlesWidgetState extends State<ZenParticlesWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _rng = Random(42);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // 25 adet optimize partikül oluştur
    for (int i = 0; i < 25; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        speed: 0.15 + _rng.nextDouble() * 0.45,
        size: 2.0 + _rng.nextDouble() * 4.0,
        opacity: 0.2 + _rng.nextDouble() * 0.5,
        phase: _rng.nextDouble() * 2 * pi,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ZenParticlesPainter(
              particles: _particles,
              progress: _controller.value,
              trackType: widget.trackType,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ZenParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final String? trackType;

  _ZenParticlesPainter({
    required this.particles,
    required this.progress,
    required this.trackType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..isAntiAlias = true;

    // Temaya göre renk ve davranış
    if (trackType == 'synth_rain') {
      // Huzurlu Yağmur: İnce serin damlalar aşağı akar
      paint.strokeCap = StrokeCap.round;
      paint.strokeWidth = 1.6;
      for (final p in particles) {
        final curY = ((p.y + progress * p.speed * 2.5) % 1.0) * size.height;
        final curX = p.x * size.width;
        paint.color = const Color(0xFF80D8FF).withValues(alpha: p.opacity * 0.7);
        canvas.drawLine(
          Offset(curX, curY),
          Offset(curX, curY + p.size * 3.5),
          paint,
        );
      }
    } else if (trackType == 'synth_lofi') {
      // Soft Lofi Beats: Sıcak mor ve kehribar küreler yavaşça yukarı süzülür
      for (int i = 0; i < particles.length; i++) {
        final p = particles[i];
        final curY = ((p.y - progress * p.speed * 0.8) % 1.0) * size.height;
        final curX = (p.x + 0.05 * sin(progress * 2 * pi + p.phase)) * size.width;
        final color = (i % 2 == 0)
            ? const Color(0xFFB388FF) // Pastel lavanta
            : const Color(0xFFFFD54F); // Sıcak kehribar
        paint.color = color.withValues(alpha: p.opacity * 0.45);
        canvas.drawCircle(Offset(curX, curY), p.size * 1.8, paint);
      }
    } else if (trackType == 'synth_zen') {
      // Derin Zen / 432 Hz: Sakin merkezli nefes dalgaları ve dingin teal küreler
      final center = Offset(size.width / 2, size.height / 2);
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..isAntiAlias = true;

      for (int i = 0; i < 3; i++) {
        final ringProgress = (progress + (i * 0.33)) % 1.0;
        final radius = (size.width * 0.45) * ringProgress;
        final alpha = (1.0 - ringProgress) * 0.25;
        ringPaint.color = const Color(0xFF80CBC4).withValues(alpha: alpha);
        canvas.drawCircle(center, radius, ringPaint);
      }

      for (final p in particles) {
        final curY = ((p.y + progress * p.speed * 0.4) % 1.0) * size.height;
        final curX = (p.x + 0.03 * cos(progress * 2 * pi + p.phase)) * size.width;
        paint.color = const Color(0xFF80CBC4).withValues(alpha: p.opacity * 0.35);
        canvas.drawCircle(Offset(curX, curY), p.size * 1.2, paint);
      }
    } else {
      // Çam Ormanı & Esinti (veya varsayılan): Yeşil/nane süzülen yapraklar
      for (final p in particles) {
        final curY = ((p.y + progress * p.speed * 0.6) % 1.0) * size.height;
        final curX = ((p.x + progress * p.speed * 0.9) % 1.0) * size.width;
        paint.color = const Color(0xFFA5D6A7).withValues(alpha: p.opacity * 0.4);
        canvas.drawCircle(Offset(curX, curY), p.size * 1.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ZenParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.trackType != trackType;
  }
}

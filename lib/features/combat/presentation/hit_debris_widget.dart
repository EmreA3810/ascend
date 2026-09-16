import 'dart:math';
import 'package:flutter/material.dart';
import '../data/boss_monster.dart';

/// Canavara kılıç veya darbe indiğinde canavarın gövdesinden fiziksel olarak
/// etrafa saçılan taş/kaya parçacıkları, kıymıklar, közler ve kıvılcım şarapneli.
class BossHitDebrisWidget extends StatefulWidget {
  final BossMonster boss;
  final bool isHit;
  final Widget child;

  const BossHitDebrisWidget({
    super.key,
    required this.boss,
    required this.isHit,
    required this.child,
  });

  @override
  State<BossHitDebrisWidget> createState() => _BossHitDebrisWidgetState();
}

class _BossHitDebrisWidgetState extends State<BossHitDebrisWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<_DebrisParticle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
  }

  @override
  void didUpdateWidget(covariant BossHitDebrisWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHit && !oldWidget.isHit) {
      _spawnDebris();
      _animController.forward(from: 0.0);
    }
  }

  void _spawnDebris() {
    _particles.clear();
    final colors = _getColorsForBoss(widget.boss.id);

    // 10 adet fiziksel kaya/kıymık parçası (yerçekimi ve dönme ile)
    for (int i = 0; i < 10; i++) {
      // Çoğunlukla sola ve yukarı (kahramanın vurduğu yönden dışarıya doğru)
      final angle = (pi * 0.55) + (_rng.nextDouble() * pi * 0.9);
      final speed = 45.0 + _rng.nextDouble() * 75.0;
      final size = 4.0 + _rng.nextDouble() * 5.5;

      _particles.add(
        _DebrisParticle(
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 25.0, // Yukarı sıçrama
          gravity: 120.0,
          size: size,
          rotationSpeed: (_rng.nextDouble() - 0.5) * 12.0,
          color: colors[_rng.nextInt(colors.length)],
          isSpark: false,
        ),
      );
    }

    // 6 adet hızlı kıvılcım / köz parçası (yüksek hız, sıfır yerçekimi)
    for (int i = 0; i < 6; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 60.0 + _rng.nextDouble() * 70.0;

      _particles.add(
        _DebrisParticle(
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          gravity: 30.0,
          size: 2.0 + _rng.nextDouble() * 2.5,
          rotationSpeed: 0.0,
          color: widget.boss.accentColor,
          isSpark: true,
        ),
      );
    }
  }

  List<Color> _getColorsForBoss(String bossId) {
    switch (bossId) {
      case 'sloth_titan':
        return const [
          Color(0xFF5D534E),
          Color(0xFF423B38),
          Color(0xFF8D8078),
          Color(0xFF00E5FF), // Kristal kıymığı
        ];
      case 'fatigue_golem':
        return const [
          Color(0xFF3E2723),
          Color(0xFF5D4037),
          Color(0xFFFF7043), // Magma kıvılcımı
          Color(0xFFFFB74D),
        ];
      case 'procrastination_demon':
        return const [
          Color(0xFFB71C1C),
          Color(0xFF210D1B),
          Color(0xFFFF5252),
          Color(0xFFE040FB),
        ];
      case 'distraction_dragon':
        return const [
          Color(0xFFFF6F00),
          Color(0xFFFF8F00),
          Color(0xFFFFD54F),
          Color(0xFFD84315),
        ];
      case 'bug_queen':
        return const [
          Color(0xFF1B5E20),
          Color(0xFF00E676),
          Color(0xFFAEEA00),
          Color(0xFF76FF03),
        ];
      case 'anxiety_wraith':
        return const [
          Color(0xFF4A148C),
          Color(0xFF7B1FA2),
          Color(0xFFE1BEE7),
          Color(0xFFBA68C8),
        ];
      case 'time_thief':
      default:
        return const [
          Color(0xFF263238),
          Color(0xFF37474F),
          Color(0xFFFFD54F),
          Color(0xFFECEFF1),
        ];
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: _DebrisPainter(
            particles: _particles,
            progress: _animController.value,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _DebrisParticle {
  final double vx;
  final double vy;
  final double gravity;
  final double size;
  final double rotationSpeed;
  final Color color;
  final bool isSpark;

  _DebrisParticle({
    required this.vx,
    required this.vy,
    required this.gravity,
    required this.size,
    required this.rotationSpeed,
    required this.color,
    required this.isSpark,
  });
}

class _DebrisPainter extends CustomPainter {
  final List<_DebrisParticle> particles;
  final double progress;

  _DebrisPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0 || particles.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final t = progress;
    final opacity = (1.0 - t).clamp(0.0, 1.0);

    // 1. Darbe Şok Dalgası Halkası (Genişleyen ve sönen halka)
    if (t < 0.6) {
      final shockProgress = t / 0.6;
      final shockRadius = 15.0 + (shockProgress * 40.0);
      final shockPaint = Paint()
        ..color = Colors.white.withValues(alpha: (1.0 - shockProgress) * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * (1.0 - shockProgress);
      canvas.drawCircle(center, shockRadius, shockPaint);
    }

    // 2. Fiziksel Parçacıklar (Kaya kıymıkları, közler, pullar)
    for (final p in particles) {
      final x = center.dx + (p.vx * t);
      final y = center.dy + (p.vy * t) + (0.5 * p.gravity * t * t);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotationSpeed * t);

      if (p.isSpark) {
        // Parlayan minik kıvılcım (hafif glow ile)
        canvas.drawCircle(Offset.zero, p.size * (1.0 - (t * 0.4)), paint);
      } else {
        // Düzensiz çokgen kaya parçası
        final s = p.size * (1.0 - (t * 0.3));
        final path = Path();
        path.moveTo(-s * 0.6, -s * 0.4);
        path.lineTo(s * 0.5, -s * 0.7);
        path.lineTo(s * 0.7, s * 0.5);
        path.lineTo(-s * 0.3, s * 0.8);
        path.close();
        canvas.drawPath(path, paint);

        // Kenar ışığı / derinlik
        final outlinePaint = Paint()
          ..color = Colors.black.withValues(alpha: opacity * 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;
        canvas.drawPath(path, outlinePaint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _DebrisPainter oldDelegate) => true;
}

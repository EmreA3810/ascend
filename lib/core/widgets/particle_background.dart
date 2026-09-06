import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.opacity,
  });
}

class ParticleBackground extends StatefulWidget {
  const ParticleBackground({super.key});

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();
  final int _particleCount = 20;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initParticles(Size size) {
    if (_particles.isNotEmpty) return;
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        Particle(
          x: _random.nextDouble() * size.width,
          y: _random.nextDouble() * size.height,
          vx: (_random.nextDouble() - 0.5) * 0.3,
          vy: (_random.nextDouble() - 0.5) * 0.3,
          radius: _random.nextDouble() * 2.0 + 1.0,
          opacity: _random.nextDouble() * 0.45 + 0.15,
        ),
      );
    }
  }

  void _updateParticles(Size size) {
    for (final p in _particles) {
      p.x += p.vx;
      p.y += p.vy;

      // Bound checks
      if (p.x < 0) p.x = size.width;
      if (p.x > size.width) p.x = 0;
      if (p.y < 0) p.y = size.height;
      if (p.y > size.height) p.y = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _initParticles(size);

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            _updateParticles(size);
            return CustomPaint(
              size: size,
              painter: _ParticlePainter(_particles),
            );
          },
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      paint.color = AppColors.secondary.withValues(alpha: p.opacity);
      canvas.drawCircle(Offset(p.x, p.y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

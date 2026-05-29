import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Neon efektli animasyonlu ilerleme çubuğu widget'ı.
///
/// Stat değerleri değiştiğinde yumuşak animasyonla güncellenir.
/// Cyberpunk tarzı neon glow efekti ve gradient dolgu içerir.
class AnimatedStatBar extends StatefulWidget {
  /// Çubuğun üzerinde gösterilecek etiket (ör. "Focus", "Energy")
  final String label;

  /// Mevcut değer
  final int value;

  /// Maksimum değer
  final int maxValue;

  /// Çubuğun ana rengi — neon glow bu renge göre oluşturulur
  final Color color;

  /// Etiket ve değer satırının gösterilip gösterilmeyeceği
  final bool showLabel;

  /// Çubuğun yüksekliği (piksel)
  final double height;

  const AnimatedStatBar({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    this.showLabel = true,
    this.height = 8,
  });

  @override
  State<AnimatedStatBar> createState() => _AnimatedStatBarState();
}

class _AnimatedStatBarState extends State<AnimatedStatBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  /// Önceki doluluk oranı — animasyonun başlangıç noktası
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // İlk animasyonu başlat (0'dan mevcut değere)
    _setupAnimation(0.0, _targetProgress);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedStatBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Değer veya maxValue değiştiğinde yeniden animasyon uygula
    if (oldWidget.value != widget.value ||
        oldWidget.maxValue != widget.maxValue) {
      _previousProgress = _animation.value;
      _setupAnimation(_previousProgress, _targetProgress);
      _controller.forward(from: 0.0);
    }
  }

  /// Hedef doluluk oranını hesapla (0.0 – 1.0 arası)
  double get _targetProgress {
    if (widget.maxValue <= 0) return 0.0;
    return (widget.value / widget.maxValue).clamp(0.0, 1.0);
  }

  /// Tween animasyonunu yapılandır
  void _setupAnimation(double from, double to) {
    _animation = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Üst satır: etiket ve değer gösterimi
        if (widget.showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Stat etiketi
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // Mevcut / Maksimum değer
                Text(
                  '${widget.value}/${widget.maxValue}',
                  style: GoogleFonts.inter(
                    color: widget.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        // Animasyonlu ilerleme çubuğu
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                // Arka plan — koyu yüzey rengi
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
              child: Stack(
                children: [
                  // Dolu kısım — gradient + neon glow
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _animation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(widget.height / 2),
                        // Gradient dolgu: ana renkten daha açık tonuna
                        gradient: LinearGradient(
                          colors: [
                            widget.color,
                            Color.lerp(widget.color, Colors.white, 0.3)!,
                          ],
                        ),
                        // Neon glow efekti
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.3),
                            blurRadius: 16,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

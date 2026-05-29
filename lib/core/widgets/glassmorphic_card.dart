import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Cam efektli (glassmorphism) kart widget'ı.
///
/// Arka plan bulanıklaştırma, yarı saydam yüzey ve neon kenarlık glow
/// efekti ile premium cyberpunk görünümü sağlar.
class GlassmorphicCard extends StatelessWidget {
  /// Kartın içeriği
  final Widget child;

  /// İçerik etrafındaki dolgu
  final EdgeInsets padding;

  /// Kenarlık rengi — null ise [AppColors.primary] kullanılır
  final Color? borderColor;

  /// Köşe yuvarlaklık yarıçapı
  final double borderRadius;

  /// Opsiyonel gradient arka plan renkleri
  /// Belirtilirse kartın arka planına gradient uygulanır
  final List<Color>? gradientColors;

  /// Neon glow efektinin açık/kapalı durumu
  final bool enableGlow;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderColor,
    this.borderRadius = 20,
    this.gradientColors,
    this.enableGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? AppColors.primary;

    return Container(
      // Neon glow efekti — dış kenarlık etrafında renkli parıltı
      decoration: enableGlow
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: effectiveBorderColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: effectiveBorderColor.withValues(alpha: 0.08),
                  blurRadius: 40,
                  spreadRadius: 0,
                ),
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          // Arka plan bulanıklaştırma — cam efekti
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              // Gradient veya düz yarı saydam arka plan
              gradient: gradientColors != null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors!
                          .map((c) => c.withValues(alpha: 0.15))
                          .toList(),
                    )
                  : null,
              color: gradientColors == null
                  ? AppColors.cardBackground.withValues(alpha: 0.7)
                  : null,
              borderRadius: BorderRadius.circular(borderRadius),
              // İnce kenarlık — neon tonlu
              border: Border.all(
                color: effectiveBorderColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

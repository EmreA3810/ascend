import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Tam ekran seviye atlama kutlama overlay'i.
///
/// Konfeti patlaması, gradient "LEVEL UP!" yazısı, seviye numarası
/// ve yeni unvan gösterimi ile premium RPG deneyimi sunar.
/// Dokunarak veya 4 saniye sonra otomatik olarak kapanır.
class LevelUpOverlay {
  /// Seviye atlama kutlamasını gösterir.
  ///
  /// [newLevel] — Ulaşılan yeni seviye numarası.
  /// [newTitle] — Yeni seviye ile kazanılan unvan.
  static void show(
    BuildContext context, {
    required int newLevel,
    required String newTitle,
  }) {
    final overlay = Overlay.of(context);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _LevelUpOverlayWidget(
        newLevel: newLevel,
        newTitle: newTitle,
        onDismiss: () {
          entry.remove();
        },
      ),
    );

    overlay.insert(entry);
  }
}

/// Overlay'in iç widget'ı — animasyon ve konfeti yönetimi burada yapılır.
class _LevelUpOverlayWidget extends StatefulWidget {
  final int newLevel;
  final String newTitle;
  final VoidCallback onDismiss;

  const _LevelUpOverlayWidget({
    required this.newLevel,
    required this.newTitle,
    required this.onDismiss,
  });

  @override
  State<_LevelUpOverlayWidget> createState() => _LevelUpOverlayWidgetState();
}

class _LevelUpOverlayWidgetState extends State<_LevelUpOverlayWidget>
    with TickerProviderStateMixin {
  // Ana giriş animasyonu: scale + fade
  late AnimationController _entryController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // "LEVEL UP!" yazısı için bounce scale animasyonu
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  // Unvan reveal animasyonu
  late AnimationController _titleRevealController;
  late Animation<double> _titleFadeAnimation;

  // Konfeti kontrolcüsü
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    // === Giriş animasyonu (scale 0.5→1.0 + fade 0→1) ===
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeIn),
    );

    // === "LEVEL UP!" bounce efekti ===
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_bounceController);

    // === Unvan reveal (fade in) ===
    _titleRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _titleRevealController, curve: Curves.easeInOut),
    );

    // === Konfeti ===
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    // Animasyon zincirini başlat
    _startAnimationSequence();
  }

  /// Animasyonları sırasıyla başlat
  Future<void> _startAnimationSequence() async {
    // 1. Giriş animasyonu
    _entryController.forward();
    _confettiController.play();

    // 2. Bounce efekti — giriş animasyonu yarılandıktan sonra
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _bounceController.forward();

    // 3. Unvan gösterimi — biraz daha bekle
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _titleRevealController.forward();

    // 4. Otomatik kapanma — 4 saniye sonra
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    _dismiss();
  }

  /// Kapanış animasyonu ve overlay'i kaldırma
  Future<void> _dismiss() async {
    await _entryController.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _bounceController.dispose();
    _titleRevealController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        return GestureDetector(
          // Dokunarak kapatma
          onTap: _dismiss,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              // Yarı saydam koyu arka plan
              color: AppColors.background.withValues(alpha: 0.85 * _fadeAnimation.value),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // === Konfeti patlaması ===
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirectionality:
                              BlastDirectionality.explosive,
                          maxBlastForce: 30,
                          minBlastForce: 10,
                          numberOfParticles: 30,
                          gravity: 0.2,
                          shouldLoop: false,
                          colors: const [
                            AppColors.primary,
                            AppColors.secondary,
                            AppColors.success,
                            AppColors.gold,
                            AppColors.statStrength,
                            AppColors.statKnowledge,
                          ],
                        ),
                      ),

                      // === Ana içerik ===
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // "LEVEL UP!" — gradient shader + bounce
                          AnimatedBuilder(
                            animation: _bounceAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _bounceAnimation.value,
                                child: ShaderMask(
                                  shaderCallback: (bounds) {
                                    return const LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.secondary,
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    'LEVEL UP!',
                                    style: GoogleFonts.inter(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Seviye numarası — neon glow ile
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.4),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Text(
                              'Level ${widget.newLevel}',
                              style: GoogleFonts.inter(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                shadows: [
                                  Shadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.8),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Yeni unvan — fade-in reveal
                          AnimatedBuilder(
                            animation: _titleFadeAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _titleFadeAnimation.value,
                                child: Transform.translate(
                                  offset: Offset(
                                      0,
                                      10 *
                                          (1 -
                                              _titleFadeAnimation.value)),
                                  child: Column(
                                    children: [
                                      Text(
                                        'New Title Unlocked',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ShaderMask(
                                        shaderCallback: (bounds) {
                                          return AppColors.goldGradient
                                              .createShader(bounds);
                                        },
                                        child: Text(
                                          widget.newTitle,
                                          style: GoogleFonts.inter(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 40),

                          // Kapatma ipucu
                          Text(
                            'Tap anywhere to continue',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

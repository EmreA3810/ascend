import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Animasyonlu XP kazanım popup'ı.
///
/// Ekranda yukarı doğru süzülerek beliren ve kaybolan neon efektli
/// floating metin gösterir. RPG tarzı XP bildirimi sağlar.
class XpGainPopup {
  /// XP kazanım popup'ını gösterir.
  ///
  /// [xp] — Kazanılan XP miktarı ("+{xp} XP" olarak gösterilir).
  /// [statName] — Opsiyonel stat adı (ör. "Focus", "Energy").
  /// [statAmount] — Opsiyonel stat artış miktarı.
  ///
  /// Stat bilgisi verilirse XP metninin altında küçük bir satır daha gösterilir.
  static void show(
    BuildContext context, {
    required int xp,
    String? statName,
    int? statAmount,
  }) {
    final overlay = Overlay.of(context);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _XpGainPopupWidget(
        xp: xp,
        statName: statName,
        statAmount: statAmount,
        onDismiss: () {
          entry.remove();
        },
      ),
    );

    overlay.insert(entry);
  }
}

/// Popup'ın iç animasyon widget'ı.
/// OverlayEntry içinde kullanılır ve kendi AnimationController'ını yönetir.
class _XpGainPopupWidget extends StatefulWidget {
  final int xp;
  final String? statName;
  final int? statAmount;
  final VoidCallback onDismiss;

  const _XpGainPopupWidget({
    required this.xp,
    this.statName,
    this.statAmount,
    required this.onDismiss,
  });

  @override
  State<_XpGainPopupWidget> createState() => _XpGainPopupWidgetState();
}

class _XpGainPopupWidgetState extends State<_XpGainPopupWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _translateY;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    // ~2 saniyelik toplam animasyon (daha uzun ve dramatic)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Yukarı doğru hareket: 0 → -140 piksel
    _translateY = Tween<double>(begin: 0, end: -140).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Opaklık: hızlı belir, yavaşça kaybol
    // 0.0→0.2 : fade in  |  0.2→0.7 : tam görünür  |  0.7→1.0 : fade out
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_controller);

    // Animasyon bitince overlay'den kaldır
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Stat adına göre renk döndürür
  Color _getStatColor(String statName) {
    switch (statName.toLowerCase()) {
      case 'focus':
        return AppColors.statFocus;
      case 'energy':
        return AppColors.statEnergy;
      case 'knowledge':
        return AppColors.statKnowledge;
      case 'strength':
        return AppColors.statStrength;
      default:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Scale animation: burst out then settle
        final scaleValue = _controller.value > 0.1 ? 1.0 : (1.0 + (_controller.value * 10 * 0.2));
        
        return Positioned(
          // Ekranın alt-ortasına yerleştir
          bottom: screenSize.height * 0.35,
          left: 0,
          right: 0,
          child: Transform.translate(
            offset: Offset(0, _translateY.value),
            child: Transform.scale(
              scale: scaleValue,
              child: Opacity(
                opacity: _opacity.value,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "+{xp} XP" — yeşil neon metin, daha büyük
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            AppColors.success,
                            Color.lerp(AppColors.success, Colors.white, 0.3)!,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          '+${widget.xp} XP',
                          style: GoogleFonts.inter(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: AppColors.success.withValues(alpha: 1.0),
                                blurRadius: 24,
                              ),
                              Shadow(
                                color: AppColors.success.withValues(alpha: 0.6),
                                blurRadius: 48,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Opsiyonel stat bilgisi satırı
                      if (widget.statName != null && widget.statAmount != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '+${widget.statAmount} ${widget.statName}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _getStatColor(widget.statName!),
                            shadows: [
                              Shadow(
                                color: _getStatColor(widget.statName!)
                                    .withValues(alpha: 0.8),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
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

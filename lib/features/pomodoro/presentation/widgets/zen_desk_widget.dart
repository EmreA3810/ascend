import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ascend/features/character/presentation/character_painter.dart';

/// Zen Modu için karakter odak sahnesi.
/// Masasız, karmaşasız; yalnızca karakterin huzurlu nefes alışverişi,
/// sakin meditasyon gölgesi ve yumuşak zen aurasını barındırır.
class ZenDeskWidget extends StatefulWidget {
  final Map<String, String> equippedItems;
  final bool isWorking;

  const ZenDeskWidget({
    super.key,
    required this.equippedItems,
    this.isWorking = true,
  });

  @override
  State<ZenDeskWidget> createState() => _ZenDeskWidgetState();
}

class _ZenDeskWidgetState extends State<ZenDeskWidget> with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, child) {
        final breath = sin(_breathingController.value * pi);
        final floatOffset = -4.0 * breath;

        return SizedBox(
          height: 175,
          width: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Zemin Meditasyon Parıltısı / Yumuşak Zen Aura
              Positioned(
                bottom: 12,
                child: Container(
                  width: 140 + (breath * 18),
                  height: 28 + (breath * 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(140 + (breath * 18), 28 + (breath * 6)),
                    ),
                    gradient: RadialGradient(
                      colors: [
                        (widget.isWorking
                                ? const Color(0xFF64B5F6)
                                : const Color(0xFF81C784))
                            .withValues(alpha: widget.isWorking ? 0.28 : 0.16),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Karakter Taban Gölgesi
              Positioned(
                bottom: 18,
                child: Container(
                  width: 80 - (breath * 8),
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.elliptical(80, 12)),
                    color: Colors.black.withValues(alpha: 0.35 - (breath * 0.08)),
                  ),
                ),
              ),

              // 3. Karakter Avatarı (Hafif nefes alış süzülüşü ile)
              Positioned(
                bottom: 22,
                child: Transform.translate(
                  offset: Offset(0, floatOffset),
                  child: CharacterAvatar(
                    equippedItems: widget.equippedItems,
                    size: 130,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

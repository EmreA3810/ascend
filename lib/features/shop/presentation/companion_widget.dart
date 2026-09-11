import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/companion_data.dart';
import '../../../core/utils/sound_effects.dart';

class CompanionWidget extends StatefulWidget {
  final CompanionModel companion;
  final double size;
  final bool showSpeechBubbleOnTap;
  final bool showNameTag;

  const CompanionWidget({
    super.key,
    required this.companion,
    this.size = 50,
    this.showSpeechBubbleOnTap = true,
    this.showNameTag = true,
  });

  @override
  State<CompanionWidget> createState() => _CompanionWidgetState();
}

class _CompanionWidgetState extends State<CompanionWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    SoundEffects.playStatUp();
    if (!widget.showSpeechBubbleOnTap) return;

    final quotes = widget.companion.quotes;
    if (quotes.isNotEmpty) {
      final nextQuote = quotes[_rnd.nextInt(quotes.length)];

      // Show temporary dialogue bubble
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: widget.companion.primaryColor.withValues(alpha: 0.6), width: 1.5),
          ),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.companion.primaryColor.withValues(alpha: 0.2),
                ),
                child: Text(widget.companion.emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.companion.name,
                      style: GoogleFonts.inter(
                        color: widget.companion.accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '"$nextQuote"',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final floatOffset = sin(_controller.value * pi) * 4.0;
          final scaleVal = 0.96 + (_controller.value * 0.08);

          return Transform.translate(
            offset: Offset(0, -floatOffset),
            child: Transform.scale(
              scale: scaleVal,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.companion.primaryColor.withValues(alpha: 0.35),
                          widget.companion.primaryColor.withValues(alpha: 0.05),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.companion.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: widget.companion.primaryColor.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.companion.emoji,
                      style: TextStyle(fontSize: widget.size * 0.55),
                    ),
                  ),
                  if (widget.showNameTag) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.companion.primaryColor.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.companion.name,
                        style: GoogleFonts.inter(
                          color: widget.companion.accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/utils/sound_effects.dart';
import '../../../user/providers/user_provider.dart';

class LeagueRewardDialog extends ConsumerStatefulWidget {
  final String uid;
  final String leagueTier;

  const LeagueRewardDialog({
    super.key,
    required this.uid,
    required this.leagueTier,
  });

  static Future<void> show(
    BuildContext context, {
    required String uid,
    required String leagueTier,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => LeagueRewardDialog(uid: uid, leagueTier: leagueTier),
    );
  }

  @override
  ConsumerState<LeagueRewardDialog> createState() => _LeagueRewardDialogState();
}

class _LeagueRewardDialogState extends ConsumerState<LeagueRewardDialog> {
  late ConfettiController _confettiController;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _confettiController.play();
    SoundEffects.playVictory();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Color _getLeagueColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'elmas':
        return const Color(0xFF67E8F9);
      case 'altin':
        return const Color(0xFFFFD700);
      case 'gumus':
        return const Color(0xFFC0C0C0);
      case 'bronz':
      default:
        return const Color(0xFFCD7F32);
    }
  }

  String _getLeagueName(String tier) {
    switch (tier.toLowerCase()) {
      case 'elmas':
        return '💎 Elmas Lig';
      case 'altin':
        return '🥇 Altın Lig';
      case 'gumus':
        return '🥈 Gümüş Lig';
      case 'bronz':
      default:
        return '🥉 Bronz Lig';
    }
  }

  int _getGoldAmount(String tier) {
    switch (tier.toLowerCase()) {
      case 'elmas':
        return 200;
      case 'altin':
        return 100;
      case 'gumus':
        return 50;
      case 'bronz':
      default:
        return 20;
    }
  }

  String? _getChestTitle(String tier) {
    switch (tier.toLowerCase()) {
      case 'elmas':
        return 'Nadir Sandık 🔷';
      case 'altin':
        return 'Sıradışı Sandık 🟢';
      case 'gumus':
        return 'Sıradan Sandık 📦';
      case 'bronz':
      default:
        return null;
    }
  }

  Future<void> _handleClaim() async {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);

    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.claimLeagueReward(widget.uid, widget.leagueTier);
      SoundEffects.playStatUp();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _getLeagueColor(
              widget.leagueTier,
            ).withValues(alpha: 0.9),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🏆 ${_getLeagueName(widget.leagueTier)} ödülleri envanterine eklendi!',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isClaiming = false);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final leagueColor = _getLeagueColor(widget.leagueTier);
    final leagueName = _getLeagueName(widget.leagueTier);
    final gold = _getGoldAmount(widget.leagueTier);
    final chest = _getChestTitle(widget.leagueTier);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        AlertDialog(
          backgroundColor: const Color(0xFF141923),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: leagueColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 24,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Üst Kategori Rozeti
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: leagueColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: leagueColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'SEZON ÖDÜLÜ',
                      style: GoogleFonts.inter(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Büyük Lig İkonu & Çember
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: leagueColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: leagueColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: leagueColor.withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    leagueName.split(' ')[0],
                    style: const TextStyle(fontSize: 44),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Lig Başlığı
              Text(
                leagueName,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Geçen haftaki azmin ve mücadelen için tebrikler! Ligi bu kademede tamamladığın için ödüllerin hazır.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Ödül Kartları
              Row(
                children: [
                  // Altın Kartı
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(
                            '+$gold Altın',
                            style: GoogleFonts.inter(
                              color: Colors.amber,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Lig Bonusu',
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Sandık Kartı (varsa)
                  if (chest != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: leagueColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: leagueColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              chest.split(' ').last,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              chest.split(' ').first,
                              style: GoogleFonts.inter(
                                color: leagueColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Ödül Sandığı',
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // Topla Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isClaiming ? null : _handleClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: leagueColor,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    shadowColor: leagueColor.withValues(alpha: 0.5),
                  ),
                  child: _isClaiming
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black87,
                          ),
                        )
                      : Text(
                          'Ödülleri Topla 🎉',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),

        // Üstten dökülen konfeti
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [
            Colors.green,
            Colors.blue,
            Colors.pink,
            Colors.orange,
            Colors.purple,
            Colors.amber,
          ],
        ),
      ],
    );
  }
}

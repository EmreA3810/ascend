import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class WeeklyReportDialog extends StatefulWidget {
  final int totalMinutes;
  final int totalSessions;
  final int questsCompleted;
  final int xpEarned;
  final int goldEarned;

  const WeeklyReportDialog({
    super.key,
    required this.totalMinutes,
    required this.totalSessions,
    required this.questsCompleted,
    required this.xpEarned,
    required this.goldEarned,
  });

  static void show(
    BuildContext context, {
    required int totalMinutes,
    required int totalSessions,
    required int questsCompleted,
    required int xpEarned,
    required int goldEarned,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => WeeklyReportDialog(
        totalMinutes: totalMinutes,
        totalSessions: totalSessions,
        questsCompleted: questsCompleted,
        xpEarned: xpEarned,
        goldEarned: goldEarned,
      ),
    );
  }

  @override
  State<WeeklyReportDialog> createState() => _WeeklyReportDialogState();
}

class _WeeklyReportDialogState extends State<WeeklyReportDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildDotIndicator(int pageCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isSelected = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isSelected ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondary : AppColors.textSecondary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildSlide({
    required String emoji,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required List<Color> bgGradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bgGradient.map((c) => c.withValues(alpha: 0.15)).toList(),
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 48),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: color.withValues(alpha: 0.8),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = [
      _buildSlide(
        emoji: '🔥',
        title: 'HAFTALIK SERÜVENİN',
        value: 'Harika İş Çıkardın!',
        subtitle: 'Bu hafta kendini geliştirmek ve hedeflerine ulaşmak için mükemmel bir çaba sarf ettin. İşte senin özetin...',
        color: AppColors.primary,
        bgGradient: [AppColors.primary, AppColors.secondary],
      ),
      _buildSlide(
        emoji: '⏱️',
        title: 'ODAKLANMA RAPORU',
        value: '${widget.totalMinutes} Dakika',
        subtitle: 'Toplam ${widget.totalSessions} odak seansı tamamladın. Zihnini eğittin ve disiplinini artırdın!',
        color: AppColors.secondary,
        bgGradient: [AppColors.secondary, AppColors.primary],
      ),
      _buildSlide(
        emoji: '⚔️',
        title: 'TAMAMLANAN GÖREVLER',
        value: '${widget.questsCompleted} Görev',
        subtitle: 'Canavarları alt ettin, günlük görevlerini temizledin ve hayatını seviye atlatmaya bir adım daha yaklaştın!',
        color: AppColors.success,
        bgGradient: [AppColors.success, AppColors.secondary],
      ),
      _buildSlide(
        emoji: '💎',
        title: 'KAZANILAN GANİMET',
        value: '+${widget.xpEarned} XP & +${widget.goldEarned} Altın',
        subtitle: 'Yeni ekipmanlar satın almak ve karakterini giydirmek için kasana tonlarca altın ve tecrübe ekledin!',
        color: AppColors.gold,
        bgGradient: [AppColors.gold, AppColors.warning],
      ),
      _buildSlide(
        emoji: '🚀',
        title: 'GELECEK GÖREVİ',
        value: 'Asla Durma!',
        subtitle: 'Önümüzdeki hafta yeni hedefler belirleme ve hedeflerine odaklanma zamanı. Hazır mısın Savaşçı?',
        color: AppColors.statKnowledge,
        bgGradient: [AppColors.statKnowledge, AppColors.statStrength],
      ),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 500),
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header (Close button)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                
                // Slides PageView
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: slides,
                  ),
                ),
                
                // Indicators & Action buttons
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildDotIndicator(slides.length),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentPage > 0)
                            TextButton(
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Text(
                                'Geri',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            onPressed: () {
                              if (_currentPage < slides.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            child: Text(
                              _currentPage < slides.length - 1 ? 'İleri' : 'Kapat ⚔️',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

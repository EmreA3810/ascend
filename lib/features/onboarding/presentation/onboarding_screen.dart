import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.sports_martial_arts,
      gradient: [AppColors.primary, const Color(0xFF4A28CC)],
      glowColor: AppColors.primary,
      title: 'Gerçek Hayatın\nSenin Oyunun',
      subtitle: 'Ders çalış, spor yap, kitap oku — her şey karakterini güçlendirir. Disiplin artık bir güç.',
    ),
    _OnboardingPage(
      icon: Icons.bolt_rounded,
      gradient: [AppColors.secondary, const Color(0xFF006AA0)],
      glowColor: AppColors.secondary,
      title: 'XP Kazan,\nLevel Atla',
      subtitle: 'Her görev tamamladığında XP kazanır, seviye atlarsın. Gerçek hayattaki ilerleme oyunda görünür.',
    ),
    _OnboardingPage(
      icon: Icons.emoji_events_rounded,
      gradient: [AppColors.success, const Color(0xFF008055)],
      glowColor: AppColors.success,
      title: 'Odaklan ve\nZirveye Çık',
      subtitle: 'Pomodoro ile odaklan, streak\'ini koru, arkadaşlarınla yarış. Asıl boss kendinden büyük olanın.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (ctx, i) => _buildPage(_pages[i]),
          ),
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    final isActive = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: GestureDetector(
                    onTap: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        widget.onComplete();
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF9C6FFF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _currentPage < _pages.length - 1 ? 'Devam Et' : 'Başla!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_currentPage < _pages.length - 1)
                  TextButton(
                    onPressed: widget.onComplete,
                    child: const Text('Geç', style: TextStyle(color: AppColors.textSecondary)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 80, 28, 180),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: page.gradient.map((c) => c.withValues(alpha: 0.2)).toList(),
              ),
              border: Border.all(color: page.glowColor.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: page.glowColor.withValues(alpha: 0.25),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(child: Icon(page.icon, color: Colors.white, size: 64)),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final List<Color> gradient;
  final Color glowColor;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.icon,
    required this.gradient,
    required this.glowColor,
    required this.title,
    required this.subtitle,
  });
}

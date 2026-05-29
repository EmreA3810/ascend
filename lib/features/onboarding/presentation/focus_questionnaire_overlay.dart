import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../quests/providers/quest_provider.dart';
import '../../user/providers/user_provider.dart';

class FocusQuestionnaireOverlay extends ConsumerStatefulWidget {
  final String uid;
  const FocusQuestionnaireOverlay({super.key, required this.uid});

  @override
  ConsumerState<FocusQuestionnaireOverlay> createState() => _FocusQuestionnaireOverlayState();
}

class _FocusQuestionnaireOverlayState extends ConsumerState<FocusQuestionnaireOverlay> {
  final List<String> _selectedAreas = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _options = const [
    {
      'id': 'academic',
      'title': 'Ders Çalışma & Akademi',
      'desc': 'Sınavlar, dersler ve akademik çalışmalar.',
      'icon': '🎓',
      'color': AppColors.statKnowledge,
    },
    {
      'id': 'fitness',
      'title': 'Spor & Sağlıklı Yaşam',
      'desc': 'Egzersiz, spor salonu, su içme ve sağlıklı beslenme.',
      'icon': '🏋️',
      'color': AppColors.statStrength,
    },
    {
      'id': 'reading',
      'title': 'Kişisel Gelişim & Okuma',
      'desc': 'Kitap okuma, günlük yazma ve meditasyon.',
      'icon': '📚',
      'color': AppColors.primary,
    },
    {
      'id': 'coding',
      'title': 'Yazılım & Kariyer / İş',
      'desc': 'Kodlama, proje geliştirme ve iş odaklı çalışmalar.',
      'icon': '💻',
      'color': AppColors.statFocus,
    },
  ];

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedAreas.contains(id)) {
        _selectedAreas.remove(id);
      } else {
        _selectedAreas.add(id);
      }
    });
  }

  Future<void> _submit(List<String> areas) async {
    setState(() => _isLoading = true);
    try {
      // 1. Odak alanlarını güncelle
      await ref.read(userRepositoryProvider).updateFocusAreas(widget.uid, areas);
      
      // 2. İlk görevleri oluştur
      await ref.read(questRepositoryProvider).generateQuestsForFocusAreas(widget.uid, areas);

      // Force refresh user data in Riverpod
      ref.invalidate(currentUserProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Gradient Glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 120,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    blurRadius: 120,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'YOLUNU SEÇ, KADERİNİ BELİRLE',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(color: AppColors.primary.withValues(alpha: 0.8), blurRadius: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ascend evreninde gerçek hayatını oyunlaştırmak için en çok hangi alanlara odaklanmak istediğini seç. Seçimine göre başlangıç görevlerin otomatik oluşturulacaktır.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Options List
                  Expanded(
                    child: ListView.builder(
                      itemCount: _options.length,
                      itemBuilder: (ctx, i) {
                        final opt = _options[i];
                        final id = opt['id'] as String;
                        final isSelected = _selectedAreas.contains(id);
                        final color = opt['color'] as Color;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => _toggleSelection(id),
                            child: GlassmorphicCard(
                              padding: const EdgeInsets.all(16),
                              borderColor: isSelected ? color : AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: 16,
                              enableGlow: isSelected,
                              child: Row(
                                children: [
                                  // Icon badge
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? color.withValues(alpha: 0.2) : AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? color : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      opt['icon'] as String,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          opt['title'] as String,
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          opt['desc'] as String,
                                          style: GoogleFonts.inter(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Selection Indicator
                                  Icon(
                                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: isSelected ? color : AppColors.textSecondary,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Buttons
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 8,
                            shadowColor: AppColors.primary.withValues(alpha: 0.4),
                          ),
                          onPressed: _selectedAreas.isEmpty ? null : () => _submit(_selectedAreas),
                          child: Text(
                            'KARAKTERİMİ YARAT ⚡',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => _submit(['skipped']),
                          child: Text(
                            'Atla ve Bir Daha Gösterme',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

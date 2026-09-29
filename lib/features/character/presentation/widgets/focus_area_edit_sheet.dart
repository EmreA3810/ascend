import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../user/data/user_model.dart';
import '../../../user/providers/user_provider.dart';

class FocusAreaEditSheet {
  static void show(BuildContext context, WidgetRef ref, UserModel user) {
    final List<String> currentSelected = List.from(user.focusAreas.where((a) => a != 'skipped'));

    final List<Map<String, dynamic>> options = [
      {
        'id': 'academic',
        'label': 'Ders Çalışma & Akademi',
        'desc': 'Bilgi (KNW) ve Odak (FOC) artırır',
        'icon': Icons.school_rounded,
        'color': AppColors.statKnowledge,
      },
      {
        'id': 'fitness',
        'label': 'Spor & Sağlıklı Yaşam',
        'desc': 'Güç (STR) ve Enerji (ENG) artırır',
        'icon': Icons.fitness_center_rounded,
        'color': AppColors.statStrength,
      },
      {
        'id': 'reading',
        'label': 'Kişisel Gelişim & Okuma',
        'desc': 'Bilgi (KNW) ve Güç (STR / İrade) artırır',
        'icon': Icons.menu_book_rounded,
        'color': AppColors.primary,
      },
      {
        'id': 'coding',
        'label': 'Yazılım & Kariyer / İş',
        'desc': 'Odak (FOC) ve Enerji (ENG) artırır',
        'icon': Icons.code_rounded,
        'color': AppColors.statFocus,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, color: AppColors.secondary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'ODAK ALANLARINI DÜZENLE',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seçtiğiniz odak alanlarına göre karakter statlarınız ve görevleriniz otomatik olarak şekillenir.',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  ...options.map((opt) {
                    final id = opt['id'] as String;
                    final isSelected = currentSelected.contains(id);
                    final color = opt['color'] as Color;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              currentSelected.remove(id);
                            } else {
                              currentSelected.add(id);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withValues(alpha: 0.12) : AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : AppColors.primary.withValues(alpha: 0.1),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(opt['icon'] as IconData, color: color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      opt['label'] as String,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      opt['desc'] as String,
                                      style: GoogleFonts.inter(
                                        color: isSelected ? color : AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                color: isSelected ? color : AppColors.textSecondary.withValues(alpha: 0.4),
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'İptal',
                            style: GoogleFonts.inter(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            final finalAreas = currentSelected.isEmpty ? ['skipped'] : currentSelected;
                            await ref.read(userRepositoryProvider).updateFocusAreas(user.uid, finalAreas);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Odak alanları güncellendi! Profil statlarınız uyarlandı. 🚀'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          },
                          child: Text(
                            'Kaydet',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

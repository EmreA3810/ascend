import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../user/providers/user_provider.dart';
import '../data/quest_model.dart';
import '../providers/quest_provider.dart';

class AddQuestBottomSheet extends ConsumerStatefulWidget {
  final QuestModel? initialQuest;
  const AddQuestBottomSheet({super.key, this.initialQuest});

  @override
  ConsumerState<AddQuestBottomSheet> createState() => _AddQuestBottomSheetState();
}

class _AddQuestBottomSheetState extends ConsumerState<AddQuestBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetValueController = TextEditingController(text: '1');

  int _selectedXp = 50;
  String _selectedCategory = 'custom';
  String _selectedStatBoost = 'focus';
  String _selectedIcon = 'star';
  String _selectedUnit = 'dk';

  final List<Map<String, String>> _unitOptions = const [
    {'value': 'dk', 'label': 'Dakika (dk)'},
    {'value': 'set', 'label': 'Set'},
    {'value': 'sayfa', 'label': 'Sayfa'},
    {'value': 'bardak', 'label': 'Bardak'},
    {'value': 'problem', 'label': 'Problem'},
  ];

  @override
  void initState() {
    super.initState();
    final quest = widget.initialQuest;
    if (quest != null) {
      _titleController.text = quest.title;
      _targetValueController.text = quest.targetValue.toString();
      _selectedXp = quest.xpReward;
      _selectedCategory = quest.category;
      _selectedStatBoost = quest.statBoost;
      _selectedIcon = quest.iconName;
      _selectedUnit = quest.unit;
    }
  }

  final List<int> _xpOptions = const [30, 50, 80, 100, 150];

  final List<Map<String, String>> _stats = const [
    {'value': 'focus', 'label': 'Odak', 'color': '0xFF00E5FF'},
    {'value': 'energy', 'label': 'Enerji', 'color': '0xFF7C4DFF'},
    {'value': 'knowledge', 'label': 'Bilgi', 'color': '0xFFFFAB40'},
    {'value': 'strength', 'label': 'Güç', 'color': '0xFFFF4081'},
  ];

  final List<String> _icons = const [
    'school',
    'fitness_center',
    'menu_book',
    'timer',
    'water_drop',
    'star',
    'work',
    'design_services',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _targetValueController.dispose();
    super.dispose();
  }

  Color _getStatColor(String value) {
    switch (value) {
      case 'focus':
        return AppColors.statFocus;
      case 'energy':
        return AppColors.statEnergy;
      case 'knowledge':
        return AppColors.statKnowledge;
      case 'strength':
        return AppColors.statStrength;
      default:
        return AppColors.primary;
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.value;
    if (user == null) return;

    final targetVal = int.tryParse(_targetValueController.text.trim()) ?? 1;

    final isEdit = widget.initialQuest != null;

    final questData = QuestModel(
      id: isEdit ? widget.initialQuest!.id : '',
      title: _titleController.text.trim(),
      xpReward: _selectedXp,
      category: _selectedCategory,
      iconName: _selectedIcon,
      isCompleted: isEdit ? widget.initialQuest!.isCompleted : false,
      createdAt: isEdit ? widget.initialQuest!.createdAt : DateTime.now(),
      completedAt: isEdit ? widget.initialQuest!.completedAt : null,
      statBoost: _selectedStatBoost,
      progress: isEdit ? widget.initialQuest!.progress : 0.0,
      currentValue: isEdit ? widget.initialQuest!.currentValue : 0,
      targetValue: targetVal,
      unit: _selectedUnit,
    );

    try {
      if (isEdit) {
        await ref.read(questRepositoryProvider).updateQuest(user.uid, questData);
      } else {
        await ref.read(questRepositoryProvider).addQuest(user.uid, questData);
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Görev başarıyla güncellendi! 🚀' : 'Yeni görev başarıyla eklendi! 🚀'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keyboard safety: padding at bottom
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              
              Text(
                widget.initialQuest != null ? 'GÖREVİ DÜZENLE' : 'YENİ GÖREV EKLE',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(color: AppColors.primary.withValues(alpha: 0.8), blurRadius: 10),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title input
              Text(
                'Görev Başlığı',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ders çalış, egzersiz yap...',
                  hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Başlık boş olamaz' : null,
              ),
              const SizedBox(height: 20),

              // Target Value & Unit Inputs
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hedef Değer',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _targetValueController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '1',
                            filled: true,
                            fillColor: AppColors.cardBackground,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Boş olamaz';
                            final parsed = int.tryParse(val.trim());
                            if (parsed == null || parsed <= 0) return 'Pozitif sayı girin';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Birim',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedUnit,
                          dropdownColor: AppColors.cardBackground,
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.cardBackground,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: _unitOptions.map((unit) {
                            return DropdownMenuItem<String>(
                              value: unit['value'],
                              child: Text(
                                unit['label']!,
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedUnit = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // XP Selector
              Text(
                'XP Ödülü',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _xpOptions.map((xp) {
                  final isSelected = _selectedXp == xp;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedXp = xp),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.success.withValues(alpha: 0.15) : AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.success : AppColors.primary.withValues(alpha: 0.1),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '+$xp XP',
                              style: GoogleFonts.inter(
                                color: isSelected ? AppColors.success : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),



              // Stat Boost Selector
              Text(
                'Stat Desteği',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: _stats.map((stat) {
                  final isSelected = _selectedStatBoost == stat['value'];
                  final color = _getStatColor(stat['value']!);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedStatBoost = stat['value']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : AppColors.primary.withValues(alpha: 0.1),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              stat['label']!,
                              style: GoogleFonts.inter(
                                color: isSelected ? color : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Icon Selector
              Text(
                'Simge Seç',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _icons.length,
                  itemBuilder: (ctx, i) {
                    final iconName = _icons[i];
                    final isSelected = _selectedIcon == iconName;
                    final iconData = QuestModel.iconFromName(iconName);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = iconName),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        width: 48,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          iconData,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'İptal',
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                        shadowColor: AppColors.primary.withValues(alpha: 0.5),
                      ),
                      onPressed: _submit,
                      child: Text(
                        widget.initialQuest != null ? 'Güncelle' : 'Oluştur',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

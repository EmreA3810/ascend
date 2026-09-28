import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FocusAreaConfig {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final List<String> primaryStats; // e.g. ['knowledge', 'focus']

  const FocusAreaConfig({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.primaryStats,
  });
}

class FocusAreaStatService {
  static const Map<String, FocusAreaConfig> configs = {
    'academic': FocusAreaConfig(
      id: 'academic',
      label: 'Ders Çalışma & Akademi',
      icon: Icons.school_rounded,
      color: AppColors.statKnowledge,
      primaryStats: ['knowledge', 'focus'],
    ),
    'fitness': FocusAreaConfig(
      id: 'fitness',
      label: 'Spor & Sağlıklı Yaşam',
      icon: Icons.fitness_center_rounded,
      color: AppColors.statStrength,
      primaryStats: ['strength', 'energy'],
    ),
    'reading': FocusAreaConfig(
      id: 'reading',
      label: 'Kişisel Gelişim & Okuma',
      icon: Icons.menu_book_rounded,
      color: AppColors.primary,
      primaryStats: ['knowledge', 'focus'],
    ),
    'coding': FocusAreaConfig(
      id: 'coding',
      label: 'Yazılım & Kariyer / İş',
      icon: Icons.code_rounded,
      color: AppColors.statFocus,
      primaryStats: ['focus', 'knowledge'],
    ),
  };

  /// Returns the set of stats that are relevant to the user's selected focus areas.
  /// If focusAreas is empty, contains 'skipped', or has no recognized areas, defaults to all 4 stats.
  static Set<String> getVisibleStats(List<String> userFocusAreas) {
    final valid = userFocusAreas.where((a) => a != 'skipped' && configs.containsKey(a)).toList();
    if (valid.isEmpty) {
      return {'focus', 'energy', 'knowledge', 'strength'};
    }
    final stats = <String>{};
    for (final area in valid) {
      final cfg = configs[area];
      if (cfg != null) {
        stats.addAll(cfg.primaryStats);
      }
    }
    return stats;
  }

  /// Stat boosts awarded upon completing a focus session for a given area.
  static Map<String, int> getSessionStatBoosts(String areaId) {
    switch (areaId) {
      case 'fitness':
        return {'strength': 1, 'energy': 1};
      case 'academic':
        return {'knowledge': 1, 'focus': 1};
      case 'reading':
        return {'knowledge': 1, 'focus': 1};
      case 'coding':
        return {'focus': 1, 'knowledge': 1};
      default:
        return {'focus': 1};
    }
  }

  /// Primary stat name used for display in popups and summaries.
  static String getPrimaryStat(String areaId) {
    switch (areaId) {
      case 'fitness':
        return 'strength';
      case 'academic':
        return 'knowledge';
      case 'reading':
        return 'knowledge';
      case 'coding':
        return 'focus';
      default:
        return 'focus';
    }
  }

  /// Turkish label for a stat key
  static String getStatLabel(String statKey) {
    switch (statKey.toLowerCase()) {
      case 'focus':
        return 'Odak';
      case 'energy':
        return 'Enerji';
      case 'knowledge':
        return 'Bilgi';
      case 'strength':
        return 'Güç';
      default:
        return statKey.toUpperCase();
    }
  }

  /// Short 3-letter code for a stat key
  static String getStatShortCode(String statKey) {
    switch (statKey.toLowerCase()) {
      case 'focus':
        return 'FOC';
      case 'energy':
        return 'ENG';
      case 'knowledge':
        return 'KNW';
      case 'strength':
        return 'STR';
      default:
        return statKey.toUpperCase().substring(0, min(3, statKey.length));
    }
  }

  /// Color for a stat key
  static Color getStatColor(String statKey) {
    switch (statKey.toLowerCase()) {
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
}

import 'package:flutter/material.dart';

/// Odak ve antrenman seanslarında savaşılan boss canavar veri modeli.
/// Pomodoro seansları, HIIT antrenmanları ve gelecekteki modüller tarafından ortak kullanılır.
class BossMonster {
  final String id;
  final String name;
  final String title;
  final String category; // 'academic', 'coding', 'reading', 'general', 'fitness'
  final int baseHpMultiplier; // Dakika başına HP (örn: 10 HP / dk -> 25 dk = 250 HP)
  final IconData icon;
  final String emoji;
  final Color primaryColor;
  final Color accentColor;
  final int minGold;
  final int maxGold;
  final Map<String, double> chestDropChances; // e.g. {'common': 0.40, 'rare': 0.20, 'epic': 0.08, 'legendary': 0.02}
  final String defeatQuote;
  final String escapeQuote;
  final String description;

  const BossMonster({
    required this.id,
    required this.name,
    required this.title,
    required this.category,
    this.baseHpMultiplier = 10,
    required this.icon,
    required this.emoji,
    required this.primaryColor,
    required this.accentColor,
    this.minGold = 20,
    this.maxGold = 50,
    this.chestDropChances = const {
      'common': 0.50,
      'rare': 0.25,
      'epic': 0.10,
      'legendary': 0.03,
    },
    required this.defeatQuote,
    required this.escapeQuote,
    required this.description,
  });

  /// Seans süresine (dakika) göre toplam maksimum canı hesaplar.
  int calculateMaxHp(int durationInMinutes) {
    final mins = durationInMinutes.clamp(1, 180);
    return mins * baseHpMultiplier;
  }
}

import 'package:flutter/material.dart';

class QuestXpCalculator {
  /// Hedef değer, birim ve kategoriye göre dinamik ve adil XP & Altın hesaplar
  static int calculateXp({
    required int targetValue,
    required String unit,
    required String category, // 'daily', 'weekly', 'custom'
  }) {
    final cleanUnit = unit.trim().toLowerCase();
    final safeTarget = targetValue <= 0 ? 1 : targetValue;

    // 1. Birim ve hedef miktara göre doğrudan taban puan hesaplama
    double basePoints = 25.0;

    switch (cleanUnit) {
      case 'dk':
        // Dakika bazlı hedefler (ör. 15, 30, 45, 60, 90, 120 dk...)
        if (safeTarget <= 15) {
          basePoints = 25.0;
        } else if (safeTarget <= 30) {
          basePoints = 45.0;
        } else if (safeTarget <= 45) {
          basePoints = 65.0;
        } else if (safeTarget <= 60) {
          basePoints = 90.0;
        } else if (safeTarget <= 90) {
          basePoints = 125.0;
        } else if (safeTarget <= 120) {
          basePoints = 160.0;
        } else {
          basePoints = 160.0 + ((safeTarget - 120) / 30) * 30.0;
        }
        break;

      case 'sayfa':
        // Kitap okuma hedefleri
        if (safeTarget <= 10) {
          basePoints = 25.0;
        } else if (safeTarget <= 25) {
          basePoints = 45.0;
        } else if (safeTarget <= 50) {
          basePoints = 80.0;
        } else if (safeTarget <= 100) {
          basePoints = 130.0;
        } else {
          basePoints = 130.0 + ((safeTarget - 100) / 25) * 25.0;
        }
        break;

      case 'problem':
        // Kodlama / soru çözümü
        if (safeTarget <= 1) {
          basePoints = 30.0;
        } else if (safeTarget <= 3) {
          basePoints = 65.0;
        } else if (safeTarget <= 5) {
          basePoints = 100.0;
        } else if (safeTarget <= 10) {
          basePoints = 150.0;
        } else {
          basePoints = 150.0 + (safeTarget - 10) * 18.0;
        }
        break;

      case 'set':
        // Antrenman setleri
        if (safeTarget <= 2) {
          basePoints = 30.0;
        } else if (safeTarget <= 4) {
          basePoints = 60.0;
        } else if (safeTarget <= 6) {
          basePoints = 95.0;
        } else if (safeTarget <= 10) {
          basePoints = 140.0;
        } else {
          basePoints = 140.0 + (safeTarget - 10) * 15.0;
        }
        break;

      case 'bardak':
      case 'adet':
      default:
        // Sayılabilir alışkanlıklar
        if (safeTarget <= 4) {
          basePoints = 25.0;
        } else if (safeTarget <= 8) {
          basePoints = 45.0;
        } else if (safeTarget <= 12) {
          basePoints = 70.0;
        } else {
          basePoints = 70.0 + (safeTarget - 12) * 8.0;
        }
        break;
    }

    // 2. Kategori çarpanı (Haftalık maraton görevleri uzun soluklu olduğundan 2.2 katı ödül sağlar)
    double categoryMultiplier = 1.0;
    if (category == 'weekly') {
      categoryMultiplier = 2.2;
    }

    final totalXp = (basePoints * categoryMultiplier).round();
    // Minimum 15 XP, maksimum 800 XP tavanı
    return totalXp.clamp(15, 800);
  }

  /// Kazanılacak sandık türünün anahtarını döndürür
  static String getChestRarityKey(int xpReward) {
    if (xpReward >= 200) {
      return 'legendary';
    } else if (xpReward >= 100) {
      return 'epic';
    } else if (xpReward >= 75) {
      return 'rare';
    } else if (xpReward >= 50) {
      return 'uncommon';
    } else {
      return 'common';
    }
  }

  /// Kazanılacak sandık türünün kullanıcı dostu başlığı
  static String getChestRarityName(int xpReward) {
    if (xpReward >= 200) {
      return 'Efsanevi Sandık 👑';
    } else if (xpReward >= 100) {
      return 'Epik Sandık 🟣';
    } else if (xpReward >= 75) {
      return 'Nadir Sandık 🔵';
    } else if (xpReward >= 50) {
      return 'Sıradışı Sandık 🟢';
    } else {
      return 'Sıradan Sandık 📦';
    }
  }

  /// Sandık rengi
  static Color getChestColor(int xpReward) {
    if (xpReward >= 200) {
      return Colors.orangeAccent;
    } else if (xpReward >= 100) {
      return Colors.purpleAccent;
    } else if (xpReward >= 75) {
      return Colors.blueAccent;
    } else if (xpReward >= 50) {
      return Colors.greenAccent;
    } else {
      return Colors.grey.shade400;
    }
  }
}

import 'dart:math';

/// Savaş modu hasar ve ganimet hesaplama servisi.
/// Tamamen saf (pure) fonksiyonlardan oluşur, sıfır sapma (drift) ile
/// mevcut timer'ı tek kaynak alarak HP ve ödül hesaplar.
class CombatCalculator {
  /// Kalan süreye göre canavarın güncel kalan HP'sini hesaplar.
  /// Formül: ((currentSecondsLeft / totalSeconds) * maxHp).ceil()
  /// Sınır değerler: [0, maxHp] arasında kelepçelenir.
  static int calculateRemainingHp({
    required int currentSecondsLeft,
    required int totalSeconds,
    required int maxHp,
    int? attackInterval,
  }) {
    if (totalSeconds <= 0 || maxHp <= 0) return 0;
    if (currentSecondsLeft <= 0) return 0;
    if (currentSecondsLeft >= totalSeconds) return maxHp;

    // Vuruş tabanlı senkronize HP hesabı: Can yalnızca vuruş gerçekleştiğinde düşer
    if (attackInterval != null && attackInterval > 0) {
      final totalHits = totalSeconds ~/ attackInterval;
      if (totalHits > 0) {
        final elapsedSeconds = totalSeconds - currentSecondsLeft;
        final hitsLanded = (elapsedSeconds ~/ attackInterval).clamp(0, totalHits);
        final damage = (hitsLanded * maxHp / totalHits).round();
        final remainingHp = maxHp - damage;
        return remainingHp.clamp(currentSecondsLeft > 0 ? 1 : 0, maxHp);
      }
    }

    final ratio = currentSecondsLeft / totalSeconds;
    final hp = (ratio * maxHp).ceil();
    return hp.clamp(0, maxHp);
  }

  /// Dakika başına verilen sabit hasar miktarını hesaplar.
  static double calculateDamagePerMinute({
    required int totalSeconds,
    required int maxHp,
  }) {
    if (totalSeconds <= 0) return 0;
    final totalMinutes = totalSeconds / 60.0;
    if (totalMinutes <= 0) return 0;
    return maxHp / totalMinutes;
  }

  /// Canavar alt edildiğinde rastgele altın ödülü üretir.
  static int rollGoldReward(int minGold, int maxGold, {Random? random}) {
    final rng = random ?? Random();
    if (maxGold <= minGold) return minGold;
    return minGold + rng.nextInt(maxGold - minGold + 1);
  }

  /// Canavarın sandık olasılık tablosuna göre sandık düşüp düşmediğini belirler.
  /// Düşmezse null, düşerse 'common', 'rare', 'epic', 'legendary' döner.
  static String? rollChestDrop(
    Map<String, double> dropChances, {
    Random? random,
  }) {
    final rng = random ?? Random();
    final roll = rng.nextDouble(); // 0.0 - 1.0

    double cumulative = 0.0;
    // Nadirden sıradana doğru kontrol et
    final order = ['legendary', 'epic', 'rare', 'common'];

    for (final rarity in order) {
      final chance = dropChances[rarity] ?? 0.0;
      cumulative += chance;
      if (roll < cumulative) {
        return rarity;
      }
    }
    return null;
  }
}

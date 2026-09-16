import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:ascend/features/combat/data/boss_catalog.dart';
import 'package:ascend/features/combat/domain/combat_calculator.dart';

void main() {
  group('CombatCalculator Tests', () {
    test('HP calculation for 25 min (1500s) session and 250 HP', () {
      const totalSeconds = 25 * 60; // 1500s
      const maxHp = 250;

      // Başlangıç anı (1500s kaldı): Tam HP
      expect(
        CombatCalculator.calculateRemainingHp(
          currentSecondsLeft: 1500,
          totalSeconds: totalSeconds,
          maxHp: maxHp,
        ),
        equals(250),
      );

      // Yarı zaman (750s kaldı): Tam 125 HP
      expect(
        CombatCalculator.calculateRemainingHp(
          currentSecondsLeft: 750,
          totalSeconds: totalSeconds,
          maxHp: maxHp,
        ),
        equals(125),
      );

      // 10 dakika kaldı (600s): 100 HP
      expect(
        CombatCalculator.calculateRemainingHp(
          currentSecondsLeft: 600,
          totalSeconds: totalSeconds,
          maxHp: maxHp,
        ),
        equals(100),
      );

      // 1 saniye kaldı: En az 1 HP
      expect(
        CombatCalculator.calculateRemainingHp(
          currentSecondsLeft: 1,
          totalSeconds: totalSeconds,
          maxHp: maxHp,
        ),
        equals(1),
      );

      // Bittiğinde (0s): 0 HP
      expect(
        CombatCalculator.calculateRemainingHp(
          currentSecondsLeft: 0,
          totalSeconds: totalSeconds,
          maxHp: maxHp,
        ),
        equals(0),
      );

      // Negatif veya sınır dışı kontroller
      expect(
        CombatCalculator.calculateRemainingHp(
          currentSecondsLeft: -10,
          totalSeconds: totalSeconds,
          maxHp: maxHp,
        ),
        equals(0),
      );

      expect(
        CombatCalculator.calculateRemainingHp(
          currentSecondsLeft: 2000,
          totalSeconds: totalSeconds,
          maxHp: maxHp,
        ),
        equals(250),
      );
    });

    test('HP decreases only when attacks land (attackInterval = 10)', () {
      const totalSeconds = 1500;
      const maxHp = 250;

      // Başlangıç anı (1500s): 250 HP
      expect(
        CombatCalculator.calculateRemainingHp(
          currentSecondsLeft: 1500,
          totalSeconds: totalSeconds,
          maxHp: maxHp,
          attackInterval: 10,
        ),
        equals(250),
      );

      // 5 saniye geçti (1495s): Vuruş henüz gerçekleşmedi, can AYNI KALMALI (250)
      expect(
        CombatCalculator.calculateRemainingHp(
          currentSecondsLeft: 1495,
          totalSeconds: totalSeconds,
          maxHp: maxHp,
          attackInterval: 10,
        ),
        equals(250),
      );

      // 9 saniye geçti (1491s): Vuruş henüz gerçekleşmedi, can AYNI KALMALI (250)
      expect(
        CombatCalculator.calculateRemainingHp(
          currentSecondsLeft: 1491,
          totalSeconds: totalSeconds,
          maxHp: maxHp,
          attackInterval: 10,
        ),
        equals(250),
      );

      // 10 saniye geçti (1490s): İlk vuruş indi! Can düşmeli
      final hpAfterHit1 = CombatCalculator.calculateRemainingHp(
        currentSecondsLeft: 1490,
        totalSeconds: totalSeconds,
        maxHp: maxHp,
        attackInterval: 10,
      );
      expect(hpAfterHit1, lessThan(250));

      // 15 saniye geçti (1485s): İkinci vuruş henüz gelmedi, can hpAfterHit1 ile aynı kalmalı
      expect(
        CombatCalculator.calculateRemainingHp(
          currentSecondsLeft: 1485,
          totalSeconds: totalSeconds,
          maxHp: maxHp,
          attackInterval: 10,
        ),
        equals(hpAfterHit1),
      );
    });

    test('Damage per minute calculation', () {
      // 25 dk, 250 HP -> dk başına 10 hasar
      final dpm = CombatCalculator.calculateDamagePerMinute(
        totalSeconds: 25 * 60,
        maxHp: 250,
      );
      expect(dpm, equals(10.0));

      // 50 dk, 500 HP -> dk başına 10 hasar
      final dpm50 = CombatCalculator.calculateDamagePerMinute(
        totalSeconds: 50 * 60,
        maxHp: 500,
      );
      expect(dpm50, equals(10.0));
    });

    test('Gold reward rolling within bounds', () {
      final rng = Random(42);
      for (int i = 0; i < 50; i++) {
        final gold = CombatCalculator.rollGoldReward(20, 50, random: rng);
        expect(gold, greaterThanOrEqualTo(20));
        expect(gold, lessThanOrEqualTo(50));
      }
    });

    test('Chest drop rolling behaves within probabilities', () {
      final chances = {
        'common': 0.50,
        'rare': 0.25,
        'epic': 0.10,
        'legendary': 0.03,
      };

      // Test with mock Random to verify deterministic tiers
      final rngLegendary = _MockRandom(0.01);
      expect(CombatCalculator.rollChestDrop(chances, random: rngLegendary), equals('legendary'));

      final rngEpic = _MockRandom(0.05);
      expect(CombatCalculator.rollChestDrop(chances, random: rngEpic), equals('epic'));

      final rngNone = _MockRandom(0.95);
      expect(CombatCalculator.rollChestDrop(chances, random: rngNone), isNull);
    });
  });

  group('BossCatalog Tests', () {
    test('Thematic boss matching for categories', () {
      final academicBoss = BossCatalog.getBossForFocusArea('academic');
      expect(academicBoss.id, equals('procrastination_demon'));
      expect(academicBoss.name, contains('Erteleme'));

      final codingBoss = BossCatalog.getBossForFocusArea('coding');
      expect(codingBoss.id, equals('distraction_dragon'));

      final readingBoss = BossCatalog.getBossForFocusArea('reading');
      expect(readingBoss.id, equals('anxiety_wraith'));

      final fitnessBoss = BossCatalog.getBossForFocusArea('fitness');
      expect(fitnessBoss.id, equals('fatigue_golem'));
    });

    test('Max HP calculation scales correctly with duration', () {
      final demon = BossCatalog.getById('procrastination_demon');
      expect(demon.calculateMaxHp(25), equals(250)); // 25 * 10
      expect(demon.calculateMaxHp(50), equals(500)); // 50 * 10
      expect(demon.calculateMaxHp(15), equals(150)); // 15 * 10
    });
  });
}

class _MockRandom implements Random {
  final double value;
  _MockRandom(this.value);

  @override
  double nextDouble() => value;

  @override
  bool nextBool() => false;

  @override
  int nextInt(int max) => 0;
}

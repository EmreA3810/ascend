import 'package:flutter_test/flutter_test.dart';
import 'package:ascend/features/quests/domain/quest_xp_calculator.dart';
import 'package:ascend/features/user/data/user_model.dart';

void main() {
  group('Ekonomi Dengeleme: calculateGold Tests', () {
    test('calculateGold returns correct tiered gold rewards based on XP', () {
      // < 50 XP -> 10 Altın
      expect(QuestXpCalculator.calculateGold(xpReward: 0), 10);
      expect(QuestXpCalculator.calculateGold(xpReward: 25), 10);
      expect(QuestXpCalculator.calculateGold(xpReward: 49), 10);

      // 50-74 XP -> 20 Altın
      expect(QuestXpCalculator.calculateGold(xpReward: 50), 20);
      expect(QuestXpCalculator.calculateGold(xpReward: 65), 20);
      expect(QuestXpCalculator.calculateGold(xpReward: 74), 20);

      // 75-99 XP -> 30 Altın
      expect(QuestXpCalculator.calculateGold(xpReward: 75), 30);
      expect(QuestXpCalculator.calculateGold(xpReward: 90), 30);
      expect(QuestXpCalculator.calculateGold(xpReward: 99), 30);

      // 100-199 XP -> 45 Altın
      expect(QuestXpCalculator.calculateGold(xpReward: 100), 45);
      expect(QuestXpCalculator.calculateGold(xpReward: 150), 45);
      expect(QuestXpCalculator.calculateGold(xpReward: 199), 45);

      // 200+ XP -> 70 Altın
      expect(QuestXpCalculator.calculateGold(xpReward: 200), 70);
      expect(QuestXpCalculator.calculateGold(xpReward: 350), 70);
      expect(QuestXpCalculator.calculateGold(xpReward: 500), 70);
    });
  });

  group('UserModel: League Reward Fields Tests', () {
    test(
      'UserModel default constructor initializes league reward fields safely',
      () {
        const user = UserModel(
          uid: 'user123',
          displayName: 'Cengaver',
          email: 'warrior@ascend.com',
          level: 1,
          xp: 0,
          xpToNextLevel: 500,
          streak: 0,
          title: 'Acemi Savaşçı',
          stats: {},
        );

        expect(user.hasClaimedLeagueReward, isTrue);
        expect(user.lastLeagueTier, isNull);
      },
    );

    test(
      'UserModel fromMap and toMap serialize league reward fields properly',
      () {
        final map = {
          'uid': 'user456',
          'displayName': 'Ejder Avcısı',
          'email': 'dragon@ascend.com',
          'level': 5,
          'xp': 1200,
          'xpToNextLevel': 1300,
          'streak': 7,
          'title': 'Kıdemli Savaşçı',
          'stats': {'strength': 10},
          'hasClaimedLeagueReward': false,
          'lastLeagueTier': 'gumus',
        };

        final user = UserModel.fromMap(map);
        expect(user.hasClaimedLeagueReward, isFalse);
        expect(user.lastLeagueTier, 'gumus');

        final serialized = user.toMap();
        expect(serialized['hasClaimedLeagueReward'], isFalse);
        expect(serialized['lastLeagueTier'], 'gumus');
      },
    );

    test('UserModel copyWith works correctly with league reward fields', () {
      const user = UserModel(
        uid: 'user789',
        displayName: 'Şövalye',
        email: 'knight@ascend.com',
        level: 3,
        xp: 600,
        xpToNextLevel: 900,
        streak: 3,
        title: 'Savaşçı',
        stats: {},
        hasClaimedLeagueReward: true,
        lastLeagueTier: null,
      );

      final updated = user.copyWith(
        hasClaimedLeagueReward: false,
        lastLeagueTier: 'altin',
      );

      expect(updated.hasClaimedLeagueReward, isFalse);
      expect(updated.lastLeagueTier, 'altin');
      expect(updated.displayName, 'Şövalye');
    });
  });
}

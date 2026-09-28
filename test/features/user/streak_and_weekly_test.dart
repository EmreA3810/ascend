import 'package:flutter_test/flutter_test.dart';
import 'package:ascend/features/user/data/user_model.dart';
import 'package:ascend/features/user/data/user_repository.dart';

void main() {
  group('Haftalık Liderlik ve Sıfırlama Mantığı', () {
    test('getStartOfWeek doğru Pazartesi 00:00 tarihini hesaplar', () {
      // 2026-09-16 Çarşamba (Wednesday = 3)
      final wednesday = DateTime(2026, 9, 16, 14, 30);
      final monday = getStartOfWeek(wednesday);
      expect(monday.year, 2026);
      expect(monday.month, 9);
      expect(monday.day, 14); // 16 - 2 = 14 (Pazartesi)
      expect(monday.weekday, DateTime.monday);

      // 2026-09-20 Pazar (Sunday = 7)
      final sunday = DateTime(2026, 9, 20, 23, 59);
      final mondayFromSun = getStartOfWeek(sunday);
      expect(mondayFromSun.day, 14);
      expect(mondayFromSun.weekday, DateTime.monday);

      // 2026-09-14 Pazartesi (Monday = 1)
      final mon = DateTime(2026, 9, 14, 8, 0);
      final mondayFromMon = getStartOfWeek(mon);
      expect(mondayFromMon.day, 14);
      expect(mondayFromMon.weekday, DateTime.monday);
    });

    test('getEffectiveWeeklyXp bu haftaya ait aktiflikte tam XP döner', () {
      final startOfWeek = DateTime(2026, 9, 14, 0, 0);
      final user = UserModel(
        uid: 'u1',
        displayName: 'Test',
        email: 't@t.com',
        level: 5,
        xp: 200,
        xpToNextLevel: 500,
        streak: 3,
        weeklyXp: 450,
        lastActiveDate: DateTime(2026, 9, 15, 10, 0), // Salı (bu hafta)
        lastWeeklyReset: DateTime(2026, 9, 14, 0, 0),
        title: 'Savaşçı',
        stats: const {},
      );

      expect(user.getEffectiveWeeklyXp(startOfWeek), 450);
    });

    test('getEffectiveWeeklyXp geçen haftadan kalan aktiflikte 0 döner', () {
      final startOfWeek = DateTime(2026, 9, 14, 0, 0);
      final user = UserModel(
        uid: 'u2',
        displayName: 'Eski Oyuncu',
        email: 'old@t.com',
        level: 10,
        xp: 1200,
        xpToNextLevel: 800,
        streak: 0,
        weeklyXp: 850,
        lastActiveDate: DateTime(2026, 9, 10, 18, 0), // Geçen Perşembe (önceki hafta)
        lastWeeklyReset: DateTime(2026, 9, 7, 0, 0),
        title: 'Kahraman',
        stats: const {},
      );

      expect(user.getEffectiveWeeklyXp(startOfWeek), 0);
    });
  });

  group('Streak Gün Farkı ve Kalkan Doğrulaması', () {
    test('Aynı gün içinde giriş yapıldığında gün farkı 0 olur', () {
      final now = DateTime(2026, 9, 16, 15, 0);
      final lastActive = DateTime(2026, 9, 16, 9, 0);

      final todayUtc = DateTime.utc(now.year, now.month, now.day);
      final lastActiveUtc = DateTime.utc(lastActive.year, lastActive.month, lastActive.day);
      final diff = todayUtc.difference(lastActiveUtc).inDays;

      expect(diff, 0);
    });

    test('Dün giriş yapılmışsa gün farkı 1 olur (seri artar)', () {
      final now = DateTime(2026, 9, 16, 10, 0);
      final lastActive = DateTime(2026, 9, 15, 22, 0);

      final todayUtc = DateTime.utc(now.year, now.month, now.day);
      final lastActiveUtc = DateTime.utc(lastActive.year, lastActive.month, lastActive.day);
      final diff = todayUtc.difference(lastActiveUtc).inDays;

      expect(diff, 1);
    });

    test('Dün giriş yapılmamışsa (2 gün önce) gün farkı > 1 olur', () {
      final now = DateTime(2026, 9, 16, 10, 0);
      final lastActive = DateTime(2026, 9, 14, 20, 0); // 2 gün önce

      final todayUtc = DateTime.utc(now.year, now.month, now.day);
      final lastActiveUtc = DateTime.utc(lastActive.year, lastActive.month, lastActive.day);
      final diff = todayUtc.difference(lastActiveUtc).inDays;

      expect(diff, 2);
      expect(diff > 1, isTrue);
    });
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../user/data/user_repository.dart';
import 'achievement_model.dart';
import 'achievement_definitions.dart';

class AchievementRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserRepository _userRepository;

  AchievementRepository(this._userRepository);

  CollectionReference<Map<String, dynamic>> _achievementsCol(String uid) =>
      _db.collection('users').doc(uid).collection('achievements');

  /// Tüm başarımları başlat (henüz yoksa oluştur)
  Future<void> initializeAchievements(String uid) async {
    final existing = await _achievementsCol(uid).get();
    final existingIds = existing.docs.map((d) => d.id).toSet();

    final batch = _db.batch();
    bool hasNew = false;

    for (final def in AchievementDefinitions.all) {
      final id = def['id'] as String;
      if (existingIds.contains(id)) continue;

      hasNew = true;
      batch.set(_achievementsCol(uid).doc(id), {
        'title': def['title'],
        'description': def['description'],
        'icon': def['icon'],
        'requiredValue': def['requiredValue'],
        'currentValue': 0,
        'isUnlocked': false,
        'unlockedAt': null,
        'xpReward': def['xpReward'],
        'category': def['category'],
      });
    }

    if (hasNew) await batch.commit();
  }

  /// Belirli kategorideki başarımları kontrol et ve kilidi aç
  Future<void> checkAndUnlock(String uid, String category, int newValue) async {
    final snap = await _achievementsCol(uid)
        .where('category', isEqualTo: category)
        .where('isUnlocked', isEqualTo: false)
        .get();

    for (final doc in snap.docs) {
      final achievement = AchievementModel.fromMap(doc.data(), doc.id);

      // Güncel değeri güncelle
      await _achievementsCol(uid).doc(doc.id).update({
        'currentValue': newValue,
      });

      // Eşik geçildiyse kilidi aç
      if (newValue >= achievement.requiredValue) {
        await _achievementsCol(uid).doc(doc.id).update({
          'isUnlocked': true,
          'unlockedAt': Timestamp.fromDate(DateTime.now()),
          'currentValue': newValue,
        });

        // Başarım XP ödülü
        await _userRepository.addXp(uid, achievement.xpReward);
      }
    }
  }

  /// Stat başarımlarını kontrol et (tüm statlar >= eşik)
  Future<void> checkStatAchievements(String uid, Map<String, int> stats) async {
    if (stats.isEmpty) return;

    final minStat = stats.values.reduce((a, b) => a < b ? a : b);

    final snap = await _achievementsCol(uid)
        .where('category', isEqualTo: 'stat')
        .where('isUnlocked', isEqualTo: false)
        .get();

    for (final doc in snap.docs) {
      final achievement = AchievementModel.fromMap(doc.data(), doc.id);

      await _achievementsCol(uid).doc(doc.id).update({
        'currentValue': minStat,
      });

      if (minStat >= achievement.requiredValue) {
        await _achievementsCol(uid).doc(doc.id).update({
          'isUnlocked': true,
          'unlockedAt': Timestamp.fromDate(DateTime.now()),
          'currentValue': minStat,
        });

        await _userRepository.addXp(uid, achievement.xpReward);
      }
    }
  }

  /// Tüm başarımları gerçek zamanlı dinle
  Stream<List<AchievementModel>> watchAchievements(String uid) {
    return _achievementsCol(uid).snapshots().map((snap) => snap.docs
        .map((doc) => AchievementModel.fromMap(doc.data(), doc.id))
        .toList());
  }
}

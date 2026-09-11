import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Stream<UserModel?> watchUser(String uid) {
    return _userDoc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserModel.fromMap(snap.data()!);
    });
  }

  /// Canlı tüm kullanıcıları haftalık XP'ye göre sıralı izle
  Stream<List<UserModel>> watchLiveUsers() {
    return _db.collection('users').snapshots().map((snap) {
      final list = snap.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
      list.sort((a, b) {
        final cmp = b.weeklyXp.compareTo(a.weeklyXp);
        if (cmp != 0) return cmp;
        return b.xp.compareTo(a.xp);
      });
      return list;
    });
  }

  /// Belirli bir ligdeki canlı kullanıcıları izle
  Stream<List<UserModel>> watchLeagueUsers(String leagueTier) {
    return _db.collection('users').snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .where((u) => u.leagueTier.toLowerCase() == leagueTier.toLowerCase())
          .toList();
      list.sort((a, b) {
        final cmp = b.weeklyXp.compareTo(a.weeklyXp);
        if (cmp != 0) return cmp;
        return b.xp.compareTo(a.xp);
      });
      return list;
    });
  }

  Future<UserModel?> getUser(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return UserModel.fromMap(snap.data()!);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _userDoc(uid).update(data);
  }

  Future<void> addXp(String uid, int xpAmount) async {
    final user = await getUser(uid);
    if (user == null) return;

    int newXp = user.xp + xpAmount;
    int newLevel = user.level;
    int newXpToNext = user.xpToNextLevel;
    String newTitle = user.title;
    int newStatPoints = user.statPoints;

    // Level up loop
    while (newXp >= newXpToNext) {
      newXp -= newXpToNext;
      newLevel++;
      newStatPoints += 3; // Her seviye atlayışında 3 serbest stat puanı!
      newXpToNext = _xpForLevel(newLevel);
      newTitle = _titleForLevel(newLevel);
    }

    final newWeeklyXp = user.weeklyXp + xpAmount;
    final newLeague = _calcLeague(newWeeklyXp);

    final updateData = <String, dynamic>{
      'xp': newXp,
      'level': newLevel,
      'xpToNextLevel': newXpToNext,
      'title': newTitle,
      'statPoints': newStatPoints,
      'weeklyXp': newWeeklyXp,
      'leagueTier': newLeague,
    };
    if (newLevel > user.level) {
      updateData['hasClaimedLegacyStats'] = true;
    }

    await updateUser(uid, updateData);

    // XP kazanıldığında otomatik altın ver (1 XP = 1 Altın)
    await addGold(uid, xpAmount);
    await updateStreak(uid);
  }

  String _calcLeague(int weeklyXp) {
    if (weeklyXp >= 2500) return 'elmas';
    if (weeklyXp >= 1200) return 'altin';
    if (weeklyXp >= 500) return 'gumus';
    return 'bronz';
  }

  /// Stat puanı harcayarak yeteneği 1 birim güçlendir
  Future<void> allocateStatPoint(String uid, String statName) async {
    final user = await getUser(uid);
    if (user == null || user.statPoints <= 0) return;

    await _userDoc(uid).update({
      'statPoints': FieldValue.increment(-1),
      'stats.$statName': FieldValue.increment(1),
      'hasClaimedLegacyStats': true,
    });
  }

  /// Mevcut kullanıcılar için geçmiş seviyelerden gelen stat puanlarını talep et (Tek seferlik ve güvenlik korumalı)
  Future<void> claimLegacyStatPoints(String uid) async {
    final user = await getUser(uid);
    if (user == null || user.hasClaimedLegacyStats || user.level <= 1) return;

    final currentTotalStats = (user.stats['focus'] ?? 5) +
        (user.stats['energy'] ?? 5) +
        (user.stats['knowledge'] ?? 5) +
        (user.stats['strength'] ?? 5);
    const expectedBaseStats = 20;
    final maxTotalPointsForLevel = (user.level - 1) * 3;
    final alreadyDistributed = currentTotalStats - expectedBaseStats;
    final earnedPoints = maxTotalPointsForLevel - alreadyDistributed - user.statPoints;

    if (earnedPoints > 0) {
      await _userDoc(uid).update({
        'statPoints': FieldValue.increment(earnedPoints),
        'hasClaimedLegacyStats': true,
      });
    } else {
      await _userDoc(uid).update({
        'hasClaimedLegacyStats': true,
      });
    }
  }

  /// Günlük XP/eylem ile seriyi güncelle
  Future<void> updateStreak(String uid) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final user = await getUser(uid);
    if (user == null) return;

    final lastActive = user.lastActiveDate;
    int newStreak = user.streak;
    int newShields = user.streakShields;

    if (lastActive == null) {
      newStreak = 1;
    } else {
      final lastDay = DateTime(lastActive.year, lastActive.month, lastActive.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 1) {
        newStreak = user.streak + 1;
      } else if (diff == 0) {
        return; // Zaten bugün sayıldı
      } else {
        // diff > 1: Gün kaçırılmış!
        if (newShields > 0) {
          newShields--; // 1 Kalkan feda edilerek seri korundu
          newStreak = user.streak + 1;
        } else {
          newStreak = 1; // Kalkan yoksa sıfırlanıp 1'den başlar
        }
      }
    }

    await updateUser(uid, {
      'streak': newStreak,
      'streakShields': newShields,
      'lastActiveDate': Timestamp.fromDate(today),
    });
  }

  /// Uygulama açılışında seriyi kontrol et.
  /// Eğer dün kaçırılmışsa ve kalkan varsa otomatik seriyi korur.
  Future<bool> checkAndValidateStreak(String uid) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final user = await getUser(uid);
    if (user == null || user.lastActiveDate == null) return false;

    final lastDay = DateTime(user.lastActiveDate!.year, user.lastActiveDate!.month, user.lastActiveDate!.day);
    final diff = today.difference(lastDay).inDays;

    if (diff > 1) {
      if (user.streakShields > 0) {
        // Kalkan kullan ve dünkü tarihi kurtar
        final yesterday = today.subtract(const Duration(days: 1));
        await updateUser(uid, {
          'streakShields': FieldValue.increment(-1),
          'lastActiveDate': Timestamp.fromDate(yesterday),
        });
        return true; // Kalkan kullanıldı
      } else {
        // Kalkan yok ve gün atlanmış -> seri 0'a düşer
        if (user.streak > 0) {
          await updateUser(uid, {
            'streak': 0,
          });
        }
      }
    }
    return false;
  }

  /// Belirli bir stat'ı artır (FieldValue.increment kullanır)
  Future<void> boostStat(String uid, String statName, int amount) async {
    await _userDoc(uid).update({
      'stats.$statName': FieldValue.increment(amount),
    });
  }

  /// Genel sayaç artır (totalQuestsCompleted, totalPomodoroSessions, vb.)
  Future<void> incrementCounter(String uid, String field, int amount) async {
    await _userDoc(uid).update({
      field: FieldValue.increment(amount),
    });
  }

  /// Odak alanlarını güncelle
  Future<void> updateFocusAreas(String uid, List<String> focusAreas) async {
    await updateUser(uid, {
      'focusAreas': focusAreas,
    });
  }

  /// Altın ekle (1 XP = 1 Altın veya sandık satışından)
  Future<void> addGold(String uid, int amount) async {
    await _userDoc(uid).update({
      'gold': FieldValue.increment(amount),
    });
  }

  /// Altın Harca (Karakter Giysi satın alma vb.)
  Future<void> spendGold(String uid, int amount) async {
    await _userDoc(uid).update({
      'gold': FieldValue.increment(-amount),
    });
  }

  /// Envantere sandık ekle
  Future<void> addChest(String uid, String rarity) async {
    await _userDoc(uid).update({
      'chestsEarned.$rarity': FieldValue.increment(1),
    });
  }

  /// Sandık satarak Altın kazan
  Future<void> sellChest(String uid, String rarity, int goldValue) async {
    await _userDoc(uid).update({
      'chestsEarned.$rarity': FieldValue.increment(-1),
      'gold': FieldValue.increment(goldValue),
    });
  }

  /// Sandık aç ve ekipman kilidi kaldır
  Future<void> openChest(String uid, String rarity, String itemId) async {
    await _userDoc(uid).update({
      'chestsEarned.$rarity': FieldValue.increment(-1),
      'unlockedItems': FieldValue.arrayUnion([itemId]),
    });
  }

  /// Doğrudan Altın harcayarak giysi kilidi aç
  Future<void> unlockItemDirectly(String uid, String itemId, int goldCost) async {
    await spendGold(uid, goldCost);
    await _userDoc(uid).update({
      'unlockedItems': FieldValue.arrayUnion([itemId]),
    });
  }

  /// Ekipman kuşan/değiştir (slot: hat, torso, pants)
  Future<void> equipItem(String uid, String slot, String itemId) async {
    await _userDoc(uid).update({
      'equippedItems.$slot': itemId,
    });
  }

  /// Streak Kalkanı satın al (Maksimum 3 adet)
  Future<bool> buyStreakShield(String uid, int cost) async {
    final user = await getUser(uid);
    if (user == null) return false;
    if (user.gold < cost) return false;
    if (user.streakShields >= 3) return false;

    await _userDoc(uid).update({
      'gold': FieldValue.increment(-cost),
      'streakShields': FieldValue.increment(1),
    });
    return true;
  }

  /// Yoldaş satın al (Seviye ve altın kontrolü)
  Future<bool> buyCompanion(String uid, String companionId, int cost, int requiredLevel) async {
    final user = await getUser(uid);
    if (user == null) return false;
    if (user.level < requiredLevel) return false;
    if (user.gold < cost) return false;
    if (user.unlockedCompanions.contains(companionId)) return false;

    final updates = <String, dynamic>{
      'gold': FieldValue.increment(-cost),
      'unlockedCompanions': FieldValue.arrayUnion([companionId]),
    };
    if (user.equippedCompanion == null) {
      updates['equippedCompanion'] = companionId;
    }

    await _userDoc(uid).update(updates);
    return true;
  }

  /// Yoldaş kuşan
  Future<void> equipCompanion(String uid, String companionId) async {
    await _userDoc(uid).update({
      'equippedCompanion': companionId,
    });
  }

  /// Yoldaşı çıkar
  Future<void> unequipCompanion(String uid) async {
    await _userDoc(uid).update({
      'equippedCompanion': null,
    });
  }

  int _xpForLevel(int level) => 500 + (level - 1) * 200;

  String _titleForLevel(int level) {
    if (level >= 50) return 'Efsanevi Kahraman';
    if (level >= 30) return 'Usta Savaşçı';
    if (level >= 20) return 'Elit Savaşçı';
    if (level >= 15) return 'Deneyimli Savaşçı';
    if (level >= 10) return 'Kahraman';
    if (level >= 7) return 'Disiplinli Savaşçı';
    if (level >= 5) return 'Kararlı Savaşçı';
    if (level >= 3) return 'Yeni Savaşçı';
    return 'Acemi Savaşçı';
  }
}

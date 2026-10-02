import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';
import '../../../core/services/title_service.dart';

enum StreakCheckResult {
  valid,
  shieldProtected,
  broken,
}

DateTime getStartOfWeek([DateTime? referenceDate]) {
  final now = referenceDate ?? DateTime.now();
  final date = DateTime(now.year, now.month, now.day);
  final daysSinceMonday = date.weekday - DateTime.monday;
  return date.subtract(Duration(days: daysSinceMonday));
}

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
      final startOfWeek = getStartOfWeek();
      final list = snap.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
      list.sort((a, b) {
        final aXp = a.getEffectiveWeeklyXp(startOfWeek);
        final bXp = b.getEffectiveWeeklyXp(startOfWeek);
        final cmp = bXp.compareTo(aXp);
        if (cmp != 0) return cmp;
        return b.xp.compareTo(a.xp);
      });
      return list;
    });
  }

  /// Belirli bir ligdeki canlı kullanıcıları izle
  Stream<List<UserModel>> watchLeagueUsers(String leagueTier) {
    return _db.collection('users').snapshots().map((snap) {
      final startOfWeek = getStartOfWeek();
      final list = snap.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .where((u) => u.leagueTier.toLowerCase() == leagueTier.toLowerCase())
          .toList();
      list.sort((a, b) {
        final aXp = a.getEffectiveWeeklyXp(startOfWeek);
        final bXp = b.getEffectiveWeeklyXp(startOfWeek);
        final cmp = bXp.compareTo(aXp);
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

    final updatedUnlockedTitles = List<String>.from(user.unlockedTitles);
    if (!updatedUnlockedTitles.contains(user.title)) {
      updatedUnlockedTitles.add(user.title);
    }

    // Level up loop
    while (newXp >= newXpToNext) {
      newXp -= newXpToNext;
      newLevel++;
      newStatPoints += 3; // Her seviye atlayışında 3 serbest stat puanı!
      newXpToNext = _xpForLevel(newLevel);

      // Odak alanına özel rastgele unvan düşür
      final dropped = TitleService.getRandomTitleForUser(user.focusAreas, updatedUnlockedTitles);
      if (dropped != null) {
        updatedUnlockedTitles.add(dropped.title);
        if (newTitle == 'Acemi Savaşçı' || newTitle.isEmpty) {
          newTitle = dropped.title;
        }
      } else {
        final fallbackTitle = _titleForLevel(newLevel);
        if (!updatedUnlockedTitles.contains(fallbackTitle)) {
          updatedUnlockedTitles.add(fallbackTitle);
        }
      }
    }

    // Haftalık XP kontrolü (Pazartesi 00:00 sıfırlama sınırına göre)
    final startOfWeek = getStartOfWeek();
    int baseWeeklyXp = user.weeklyXp;
    DateTime? lastReset = user.lastWeeklyReset;
    bool hasClaimedLeagueReward = user.hasClaimedLeagueReward;
    String? lastLeagueTier = user.lastLeagueTier;

    if (lastReset == null || lastReset.isBefore(startOfWeek)) {
      // Yeni hafta! Eski haftanın XP'si sıfırlanıp yeni XP sıfırın üzerine eklenir.
      if (lastReset != null) {
        // Önceki haftadan kalan lig seviyesi için ödül talep edilmeye hazır
        lastLeagueTier = user.leagueTier;
        hasClaimedLeagueReward = false;
      }
      baseWeeklyXp = 0;
      lastReset = startOfWeek;
    }

    final newWeeklyXp = baseWeeklyXp + xpAmount;
    final newLeague = _calcLeague(newWeeklyXp);

    final updateData = <String, dynamic>{
      'xp': newXp,
      'level': newLevel,
      'xpToNextLevel': newXpToNext,
      'title': newTitle,
      'unlockedTitles': updatedUnlockedTitles,
      'statPoints': newStatPoints,
      'weeklyXp': newWeeklyXp,
      'lastWeeklyReset': Timestamp.fromDate(lastReset),
      'leagueTier': newLeague,
      'hasClaimedLeagueReward': hasClaimedLeagueReward,
      'lastLeagueTier': lastLeagueTier,
    };
    if (newLevel > user.level) {
      updateData['hasClaimedLegacyStats'] = true;
    }

    await updateUser(uid, updateData);

    // Seri güncellemesi
    await updateStreak(uid);
  }

  /// Kullanıcının aktif unvanını günceller
  Future<void> selectActiveTitle(String uid, String newTitle) async {
    await updateUser(uid, {'title': newTitle});
  }

  /// Yeni bir unvanın kilidini açar
  Future<void> unlockTitle(String uid, String title) async {
    await _userDoc(uid).update({
      'unlockedTitles': FieldValue.arrayUnion([title]),
    });
  }

  String _calcLeague(int weeklyXp) {
    if (weeklyXp >= 4000) return 'elmas';
    if (weeklyXp >= 2000) return 'altin';
    if (weeklyXp >= 750) return 'gumus';
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

  /// Günlük XP/eylem ile seriyi güncelle (UTC tabanlı gün farkı hesabı)
  Future<void> updateStreak(String uid) async {
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final user = await getUser(uid);
    if (user == null) return;

    final lastActive = user.lastActiveDate;
    int newStreak = user.streak;
    int newShields = user.streakShields;

    if (lastActive == null) {
      newStreak = 1;
    } else {
      final lastActiveUtc = DateTime.utc(lastActive.year, lastActive.month, lastActive.day);
      final diff = todayUtc.difference(lastActiveUtc).inDays;
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
      'lastActiveDate': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
    });
  }

  /// Uygulama açılışında seriyi kontrol et.
  /// Eğer dün kaçırılmışsa ve kalkan varsa otomatik seriyi korur.
  Future<StreakCheckResult> checkAndValidateStreak(String uid) async {
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final user = await getUser(uid);
    if (user == null || user.lastActiveDate == null) return StreakCheckResult.valid;

    final lastActive = user.lastActiveDate!;
    final lastActiveUtc = DateTime.utc(lastActive.year, lastActive.month, lastActive.day);
    final diff = todayUtc.difference(lastActiveUtc).inDays;

    if (diff > 1) {
      if (user.streakShields > 0) {
        // Kalkan kullan ve dünkü tarihi kurtar
        final yesterday = now.subtract(const Duration(days: 1));
        await updateUser(uid, {
          'streakShields': FieldValue.increment(-1),
          'lastActiveDate': Timestamp.fromDate(DateTime(yesterday.year, yesterday.month, yesterday.day)),
        });
        return StreakCheckResult.shieldProtected; // Kalkan kullanıldı
      } else {
        // Kalkan yok ve gün atlanmış -> seri 0'a düşer
        if (user.streak > 0) {
          await updateUser(uid, {
            'streak': 0,
          });
          return StreakCheckResult.broken;
        }
      }
    }
    return StreakCheckResult.valid;
  }

  /// Haftalık lig sıfırlamasını denetle ve gerekirse haftalık XP'yi 0 yap.
  Future<bool> ensureWeeklyReset(String uid) async {
    final user = await getUser(uid);
    if (user == null) return false;

    final startOfWeek = getStartOfWeek();
    if (user.lastWeeklyReset == null || user.lastWeeklyReset!.isBefore(startOfWeek)) {
      final isTransition = user.lastWeeklyReset != null;
      await updateUser(uid, {
        'weeklyXp': 0,
        'lastWeeklyReset': Timestamp.fromDate(startOfWeek),
        'leagueTier': _calcLeague(0),
        'hasClaimedLeagueReward': !isTransition,
        'lastLeagueTier': isTransition ? user.leagueTier : null,
      });
      return true; // Yeni haftaya geçildi ve sıfırlandı
    }
    return false;
  }

  /// Haftalık lig ödülünü talep et (Altın ve Sandık verir)
  Future<Map<String, dynamic>> claimLeagueReward(String uid, String tier) async {
    int goldReward = 20;
    String? chestReward;

    switch (tier.toLowerCase()) {
      case 'elmas':
        goldReward = 200;
        chestReward = 'rare';
        break;
      case 'altin':
        goldReward = 100;
        chestReward = 'uncommon';
        break;
      case 'gumus':
        goldReward = 50;
        chestReward = 'common';
        break;
      case 'bronz':
      default:
        goldReward = 20;
        chestReward = null;
        break;
    }

    final updates = <String, dynamic>{
      'gold': FieldValue.increment(goldReward),
      'hasClaimedLeagueReward': true,
    };

    if (chestReward != null) {
      updates['chestsEarned.$chestReward'] = FieldValue.increment(1);
    }

    await _userDoc(uid).update(updates);

    return {
      'gold': goldReward,
      'chest': chestReward,
      'tier': tier,
    };
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

  /// Altın ekle (görev tamamlama, lig ödülü veya sandık satışından)
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
    final effectiveId = (slot == 'pants' && itemId == 'leather_greaves') ? 'baggy_pants' : itemId;
    await _userDoc(uid).update({
      'equippedItems.$slot': effectiveId,
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

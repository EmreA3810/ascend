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

    // Level up loop
    while (newXp >= newXpToNext) {
      newXp -= newXpToNext;
      newLevel++;
      newXpToNext = _xpForLevel(newLevel);
      newTitle = _titleForLevel(newLevel);
    }

    await updateUser(uid, {
      'xp': newXp,
      'level': newLevel,
      'xpToNextLevel': newXpToNext,
      'title': newTitle,
    });

    // XP kazanıldığında otomatik altın ver (1 XP = 1 Altın)
    await addGold(uid, xpAmount);
  }

  Future<void> updateStreak(String uid) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final user = await getUser(uid);
    if (user == null) return;

    final lastActive = user.lastActiveDate;
    int newStreak = user.streak;

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
        newStreak = 1; // Streak kırıldı
      }
    }

    await updateUser(uid, {
      'streak': newStreak,
      'lastActiveDate': Timestamp.fromDate(today),
    });
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

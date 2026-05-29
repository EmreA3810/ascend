import 'package:cloud_firestore/cloud_firestore.dart';
import '../../user/data/user_repository.dart';
import 'quest_model.dart';

class QuestRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserRepository _userRepository;

  QuestRepository(this._userRepository);

  CollectionReference<Map<String, dynamic>> _questsCol(String uid) =>
      _db.collection('users').doc(uid).collection('quests');

  /// Bugünün günlük görevlerini dinler (local time midnight reset)
  Stream<List<QuestModel>> watchDailyQuests(String uid) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));

    return _questsCol(uid)
        .where('category', isEqualTo: 'daily')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .where('createdAt', isLessThan: Timestamp.fromDate(startOfTomorrow))
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => QuestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Haftalık görevleri dinler
  Stream<List<QuestModel>> watchWeeklyQuests(String uid) {
    return _questsCol(uid)
        .where('category', isEqualTo: 'weekly')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => QuestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Yeni görev ekler (auto-generated ID)
  Future<void> addQuest(String uid, QuestModel quest) async {
    await _questsCol(uid).add(quest.toMap());
  }

  /// Görevi tamamla – XP ve stat boost uygula
  Future<void> completeQuest(String uid, String questId) async {
    final doc = await _questsCol(uid).doc(questId).get();
    if (!doc.exists) return;

    final quest = QuestModel.fromMap(doc.data()!, doc.id);

    await _questsCol(uid).doc(questId).update({
      'isCompleted': true,
      'completedAt': Timestamp.fromDate(DateTime.now()),
      'progress': 1.0,
    });

    // XP ve stat güncelle
    await _userRepository.addXp(uid, quest.xpReward);
    await _userRepository.boostStat(uid, quest.statBoost, 1);
    await _userRepository.incrementCounter(uid, 'totalQuestsCompleted', 1);
  }

  /// Görev sil
  Future<void> deleteQuest(String uid, String questId) async {
    await _questsCol(uid).doc(questId).delete();
  }

  /// Görev tamamlanma durumunu değiştir
  Future<void> toggleQuest(String uid, String questId, bool completed) async {
    if (completed) {
      await completeQuest(uid, questId);
    } else {
      await _questsCol(uid).doc(questId).update({
        'isCompleted': false,
        'completedAt': null,
        'progress': 0.0,
      });
    }
  }

  /// Bugünün günlük görevleri yoksa varsayılanları oluşturur
  Future<void> ensureDailyQuests(String uid) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));

    final existing = await _questsCol(uid)
        .where('category', isEqualTo: 'daily')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .where('createdAt', isLessThan: Timestamp.fromDate(startOfTomorrow))
        .get();

    if (existing.docs.isNotEmpty) return; // Bugün için zaten var

    final defaults = [
      QuestModel(
        id: '',
        title: '1 Saat Ders Çalış',
        xpReward: 80,
        category: 'daily',
        iconName: 'school',
        isCompleted: false,
        createdAt: now,
        statBoost: 'knowledge',
        progress: 0.0,
      ),
      QuestModel(
        id: '',
        title: 'Spor Yap (30 dk)',
        xpReward: 100,
        category: 'daily',
        iconName: 'fitness_center',
        isCompleted: false,
        createdAt: now,
        statBoost: 'strength',
        progress: 0.0,
      ),
      QuestModel(
        id: '',
        title: 'Kitap Oku (20 sayfa)',
        xpReward: 50,
        category: 'daily',
        iconName: 'menu_book',
        isCompleted: false,
        createdAt: now,
        statBoost: 'knowledge',
        progress: 0.0,
      ),
      QuestModel(
        id: '',
        title: '2 Pomodoro Tamamla',
        xpReward: 80,
        category: 'daily',
        iconName: 'timer',
        isCompleted: false,
        createdAt: now,
        statBoost: 'focus',
        progress: 0.0,
      ),
      QuestModel(
        id: '',
        title: '2 Litre Su İç',
        xpReward: 30,
        category: 'daily',
        iconName: 'water_drop',
        isCompleted: false,
        createdAt: now,
        statBoost: 'energy',
        progress: 0.0,
      ),
    ];

    final batch = _db.batch();
    for (final quest in defaults) {
      batch.set(_questsCol(uid).doc(), quest.toMap());
    }
    await batch.commit();
  }
}

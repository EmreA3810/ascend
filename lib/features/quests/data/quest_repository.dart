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
    return _questsCol(uid).snapshots().map((snap) {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startOfTomorrow = startOfToday.add(const Duration(days: 1));

      return snap.docs
          .map((doc) => QuestModel.fromMap(doc.data(), doc.id))
          .where((q) =>
              q.category == 'daily' &&
              q.createdAt.isAfter(startOfToday.subtract(const Duration(seconds: 1))) &&
              q.createdAt.isBefore(startOfTomorrow))
          .toList();
    });
  }

  /// Haftalık görevleri dinler
  Stream<List<QuestModel>> watchWeeklyQuests(String uid) {
    return _questsCol(uid).snapshots().map((snap) => snap.docs
        .map((doc) => QuestModel.fromMap(doc.data(), doc.id))
        .where((q) => q.category == 'weekly')
        .toList());
  }

  /// Özel görevleri dinler (tarih filtresiz, kalıcı)
  Stream<List<QuestModel>> watchCustomQuests(String uid) {
    return _questsCol(uid).snapshots().map((snap) => snap.docs
        .map((doc) => QuestModel.fromMap(doc.data(), doc.id))
        .where((q) => q.category == 'custom')
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
    if (quest.isCompleted) return; // Zaten tamamlanmış

    await _questsCol(uid).doc(questId).update({
      'isCompleted': true,
      'completedAt': Timestamp.fromDate(DateTime.now()),
      'progress': 1.0,
      'currentValue': quest.targetValue,
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
        'currentValue': 0,
      });
    }
  }

  /// Görev ilerlemesini artırır
  Future<void> incrementQuestProgress(String uid, String questId, int amount) async {
    final doc = await _questsCol(uid).doc(questId).get();
    if (!doc.exists) return;

    final quest = QuestModel.fromMap(doc.data()!, doc.id);
    if (quest.isCompleted) return; // Zaten tamamlanmış

    int newVal = quest.currentValue + amount;
    if (newVal >= quest.targetValue) {
      newVal = quest.targetValue;
      await completeQuest(uid, questId);
    } else {
      double newProgress = newVal / quest.targetValue;
      await _questsCol(uid).doc(questId).update({
        'currentValue': newVal,
        'progress': newProgress,
      });
    }
  }

  List<QuestModel> _getDailyQuestsForArea(String area, DateTime now) {
    switch (area) {
      case 'academic':
        return [
          QuestModel(
            id: '',
            title: 'Ders Çalış (60 dk)',
            xpReward: 80,
            category: 'daily',
            iconName: 'school',
            isCompleted: false,
            createdAt: now,
            statBoost: 'knowledge',
            progress: 0.0,
            currentValue: 0,
            targetValue: 60,
            unit: 'dk',
          ),
          QuestModel(
            id: '',
            title: 'Pomodoro Tamamla (2 Seans)',
            xpReward: 60,
            category: 'daily',
            iconName: 'timer',
            isCompleted: false,
            createdAt: now,
            statBoost: 'focus',
            progress: 0.0,
            currentValue: 0,
            targetValue: 2,
            unit: 'seans',
          ),
        ];
      case 'fitness':
        return [
          QuestModel(
            id: '',
            title: 'Antrenman Yap (3 Set)',
            xpReward: 100,
            category: 'daily',
            iconName: 'fitness_center',
            isCompleted: false,
            createdAt: now,
            statBoost: 'strength',
            progress: 0.0,
            currentValue: 0,
            targetValue: 3,
            unit: 'set',
          ),
          QuestModel(
            id: '',
            title: '2 Litre Su İç (10 Bardak)',
            xpReward: 40,
            category: 'daily',
            iconName: 'water_drop',
            isCompleted: false,
            createdAt: now,
            statBoost: 'energy',
            progress: 0.0,
            currentValue: 0,
            targetValue: 10,
            unit: 'bardak',
          ),
        ];
      case 'reading':
        return [
          QuestModel(
            id: '',
            title: 'Kitap Oku (20 Sayfa)',
            xpReward: 50,
            category: 'daily',
            iconName: 'menu_book',
            isCompleted: false,
            createdAt: now,
            statBoost: 'knowledge',
            progress: 0.0,
            currentValue: 0,
            targetValue: 20,
            unit: 'sayfa',
          ),
          QuestModel(
            id: '',
            title: 'Günlük Yaz & Meditasyon (15 dk)',
            xpReward: 40,
            category: 'daily',
            iconName: 'self_improvement',
            isCompleted: false,
            createdAt: now,
            statBoost: 'energy',
            progress: 0.0,
            currentValue: 0,
            targetValue: 15,
            unit: 'dk',
          ),
        ];
      case 'coding':
        return [
          QuestModel(
            id: '',
            title: 'Kod Yaz / Geliştirme (60 dk)',
            xpReward: 80,
            category: 'daily',
            iconName: 'timer',
            isCompleted: false,
            createdAt: now,
            statBoost: 'focus',
            progress: 0.0,
            currentValue: 0,
            targetValue: 60,
            unit: 'dk',
          ),
          QuestModel(
            id: '',
            title: 'Teknik Makale Oku (15 dk)',
            xpReward: 40,
            category: 'daily',
            iconName: 'school',
            isCompleted: false,
            createdAt: now,
            statBoost: 'knowledge',
            progress: 0.0,
            currentValue: 0,
            targetValue: 15,
            unit: 'dk',
          ),
        ];
      default:
        return [];
    }
  }

  List<QuestModel> _getWeeklyQuestsForArea(String area, DateTime now) {
    switch (area) {
      case 'academic':
        return [
          QuestModel(
            id: '',
            title: 'Haftalık Çalışma Serisi (300 dk)',
            xpReward: 500,
            category: 'weekly',
            iconName: 'school',
            isCompleted: false,
            createdAt: now,
            statBoost: 'knowledge',
            progress: 0.0,
            currentValue: 0,
            targetValue: 300,
            unit: 'dk',
          ),
        ];
      case 'fitness':
        return [
          QuestModel(
            id: '',
            title: 'Haftalık Spor Hedefi (150 dk)',
            xpReward: 400,
            category: 'weekly',
            iconName: 'fitness_center',
            isCompleted: false,
            createdAt: now,
            statBoost: 'strength',
            progress: 0.0,
            currentValue: 0,
            targetValue: 150,
            unit: 'dk',
          ),
        ];
      case 'reading':
        return [
          QuestModel(
            id: '',
            title: 'Haftalık Kitap Sayfa Hedefi (100 Sayfa)',
            xpReward: 300,
            category: 'weekly',
            iconName: 'menu_book',
            isCompleted: false,
            createdAt: now,
            statBoost: 'knowledge',
            progress: 0.0,
            currentValue: 0,
            targetValue: 100,
            unit: 'sayfa',
          ),
        ];
      case 'coding':
        return [
          QuestModel(
            id: '',
            title: 'Haftalık Algoritma Çözümü (5 Problem)',
            xpReward: 450,
            category: 'weekly',
            iconName: 'bolt',
            isCompleted: false,
            createdAt: now,
            statBoost: 'focus',
            progress: 0.0,
            currentValue: 0,
            targetValue: 5,
            unit: 'problem',
          ),
        ];
      default:
        return [];
    }
  }

  /// Odak alanlarına göre ilk görevleri oluşturur (anket tamamlandığında)
  Future<void> generateQuestsForFocusAreas(String uid, List<String> focusAreas) async {
    final now = DateTime.now();

    // 1. Delete existing daily and weekly quests
    final existingSnap = await _questsCol(uid).get();
    final deleteBatch = _db.batch();
    for (final doc in existingSnap.docs) {
      final cat = doc.data()['category'] as String?;
      if (cat == 'daily' || cat == 'weekly') {
        deleteBatch.delete(doc.reference);
      }
    }
    await deleteBatch.commit();

    // 2. Generate new daily & weekly quests
    final batch = _db.batch();
    if (focusAreas.isEmpty || focusAreas.contains('skipped')) {
      final defaultDailies = [
        ..._getDailyQuestsForArea('academic', now),
        ..._getDailyQuestsForArea('fitness', now),
        ..._getDailyQuestsForArea('reading', now),
      ];
      for (final quest in defaultDailies) {
        batch.set(_questsCol(uid).doc(), quest.toMap());
      }
    } else {
      // Her seçilen odak alanı için günlük ve haftalık görevleri oluştur
      for (final area in focusAreas) {
        final dailyQuests = _getDailyQuestsForArea(area, now);
        for (final q in dailyQuests) {
          batch.set(_questsCol(uid).doc(), q.toMap());
        }

        final weeklyQuests = _getWeeklyQuestsForArea(area, now);
        for (final q in weeklyQuests) {
          batch.set(_questsCol(uid).doc(), q.toMap());
        }
      }
    }

    await batch.commit();
  }

  /// Bugünün günlük görevleri yoksa odak alanlarına göre oluşturur (In-memory filtrelenmiş kontrol)
  Future<void> ensureDailyQuests(String uid) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));

    // missing index hatası almamak için tüm görevleri çekip in-memory kontrol ediyoruz
    final existingSnap = await _questsCol(uid).get();
    final hasTodayDaily = existingSnap.docs.any((doc) {
      final data = doc.data();
      final cat = data['category'] as String?;
      final createdAtTs = data['createdAt'] as Timestamp?;
      if (cat != 'daily' || createdAtTs == null) return false;
      final createdAt = createdAtTs.toDate();
      return createdAt.isAfter(startOfToday.subtract(const Duration(seconds: 1))) &&
          createdAt.isBefore(startOfTomorrow);
    });

    if (hasTodayDaily) return; // Bugün için günlük görevler zaten var

    final user = await _userRepository.getUser(uid);
    final focusAreas = user?.focusAreas ?? [];

    final List<QuestModel> defaults = [];

    // Eğer odak alanı seçilmemişse veya pas geçildiyse varsayılanları ata
    if (focusAreas.isEmpty || focusAreas.contains('skipped')) {
      defaults.addAll([
        ..._getDailyQuestsForArea('academic', now),
        ..._getDailyQuestsForArea('fitness', now),
        ..._getDailyQuestsForArea('reading', now),
      ]);
    } else {
      for (final area in focusAreas) {
        defaults.addAll(_getDailyQuestsForArea(area, now));
      }
    }

    final batch = _db.batch();
    for (final quest in defaults) {
      batch.set(_questsCol(uid).doc(), quest.toMap());
    }
    await batch.commit();
  }

  /// Görevi günceller (düzenleme için)
  Future<void> updateQuest(String uid, QuestModel quest) async {
    await _questsCol(uid).doc(quest.id).update(quest.toMap());
  }
}

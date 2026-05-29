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

  QuestModel? _getDailyQuestForArea(String area, DateTime now) {
    switch (area) {
      case 'academic':
        return QuestModel(
          id: '',
          title: 'Ders Çalış (1 Saat)',
          xpReward: 80,
          category: 'daily',
          iconName: 'school',
          isCompleted: false,
          createdAt: now,
          statBoost: 'knowledge',
          progress: 0.0,
        );
      case 'fitness':
        return QuestModel(
          id: '',
          title: 'Spor Yap (30 dk)',
          xpReward: 100,
          category: 'daily',
          iconName: 'fitness_center',
          isCompleted: false,
          createdAt: now,
          statBoost: 'strength',
          progress: 0.0,
        );
      case 'reading':
        return QuestModel(
          id: '',
          title: 'Kitap Oku (20 sayfa)',
          xpReward: 50,
          category: 'daily',
          iconName: 'menu_book',
          isCompleted: false,
          createdAt: now,
          statBoost: 'knowledge',
          progress: 0.0,
        );
      case 'coding':
        return QuestModel(
          id: '',
          title: 'Kod Yaz / Proje Geliştir (1 saat)',
          xpReward: 80,
          category: 'daily',
          iconName: 'timer',
          isCompleted: false,
          createdAt: now,
          statBoost: 'focus',
          progress: 0.0,
        );
      default:
        return null;
    }
  }

  QuestModel? _getWeeklyQuestForArea(String area, DateTime now) {
    switch (area) {
      case 'academic':
        return QuestModel(
          id: '',
          title: '10 Saat Çalışma Hedefi',
          xpReward: 500,
          category: 'weekly',
          iconName: 'school',
          isCompleted: false,
          createdAt: now,
          statBoost: 'knowledge',
          progress: 0.0,
        );
      case 'fitness':
        return QuestModel(
          id: '',
          title: 'Haftalık 3 Antrenman',
          xpReward: 400,
          category: 'weekly',
          iconName: 'fitness_center',
          isCompleted: false,
          createdAt: now,
          statBoost: 'strength',
          progress: 0.0,
        );
      case 'reading':
        return QuestModel(
          id: '',
          title: 'Bir Kitap Bitir',
          xpReward: 300,
          category: 'weekly',
          iconName: 'menu_book',
          isCompleted: false,
          createdAt: now,
          statBoost: 'knowledge',
          progress: 0.0,
        );
      case 'coding':
        return QuestModel(
          id: '',
          title: 'Haftalık Proje Commit Hedefi',
          xpReward: 500,
          category: 'weekly',
          iconName: 'timer',
          isCompleted: false,
          createdAt: now,
          statBoost: 'focus',
          progress: 0.0,
        );
      default:
        return null;
    }
  }

  /// Odak alanlarına göre ilk görevleri oluşturur (anket tamamlandığında)
  Future<void> generateQuestsForFocusAreas(String uid, List<String> focusAreas) async {
    final now = DateTime.now();
    final batch = _db.batch();

    // Filtreleme yapılmadan geçildiyse ('skipped' veya 'none'), varsayılan görevleri ata
    if (focusAreas.isEmpty || focusAreas.contains('skipped')) {
      final defaultDailies = [
        _getDailyQuestForArea('academic', now)!,
        _getDailyQuestForArea('fitness', now)!,
        _getDailyQuestForArea('reading', now)!,
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
      for (final quest in defaultDailies) {
        batch.set(_questsCol(uid).doc(), quest.toMap());
      }
    } else {
      // Her seçilen odak alanı için bir günlük ve bir haftalık görev oluştur
      for (final area in focusAreas) {
        final dailyQuest = _getDailyQuestForArea(area, now);
        if (dailyQuest != null) {
          batch.set(_questsCol(uid).doc(), dailyQuest.toMap());
        }

        final weeklyQuest = _getWeeklyQuestForArea(area, now);
        if (weeklyQuest != null) {
          batch.set(_questsCol(uid).doc(), weeklyQuest.toMap());
        }
      }
      
      // Her koşulda su içme görevini de ekleyelim
      batch.set(
        _questsCol(uid).doc(),
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
        ).toMap(),
      );
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
        _getDailyQuestForArea('academic', now)!,
        _getDailyQuestForArea('fitness', now)!,
        _getDailyQuestForArea('reading', now)!,
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
      ]);
    } else {
      for (final area in focusAreas) {
        final q = _getDailyQuestForArea(area, now);
        if (q != null) defaults.add(q);
      }
      defaults.add(QuestModel(
        id: '',
        title: '2 Litre Su İç',
        xpReward: 30,
        category: 'daily',
        iconName: 'water_drop',
        isCompleted: false,
        createdAt: now,
        statBoost: 'energy',
        progress: 0.0,
      ));
    }

    final batch = _db.batch();
    for (final quest in defaults) {
      batch.set(_questsCol(uid).doc(), quest.toMap());
    }
    await batch.commit();
  }
}

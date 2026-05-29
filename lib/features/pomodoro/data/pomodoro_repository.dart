import 'package:cloud_firestore/cloud_firestore.dart';
import '../../user/data/user_repository.dart';
import 'pomodoro_session_model.dart';

class PomodoroRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserRepository _userRepository;

  PomodoroRepository(this._userRepository);

  CollectionReference<Map<String, dynamic>> _sessionsCol(String uid) =>
      _db.collection('users').doc(uid).collection('pomodoroSessions');

  /// Oturum kaydet + XP ve stat güncelle
  Future<void> saveSession(String uid, PomodoroSessionModel session) async {
    await _sessionsCol(uid).add(session.toMap());
    await _userRepository.addXp(uid, session.xpEarned);
    await _userRepository.boostStat(uid, 'focus', 1);
    await _userRepository.incrementCounter(uid, 'totalPomodoroSessions', 1);
    await _userRepository.incrementCounter(uid, 'totalMinutesFocused', session.workMinutes);
  }

  /// Bugünkü oturumları dinler (local time)
  Stream<List<PomodoroSessionModel>> watchTodaySessions(String uid) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));

    return _sessionsCol(uid)
        .where('startedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .where('startedAt', isLessThan: Timestamp.fromDate(startOfTomorrow))
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PomodoroSessionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Bu haftanın oturumlarını dinler (Pazartesi başlangıç)
  Stream<List<PomodoroSessionModel>> watchWeekSessions(String uid) {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return _sessionsCol(uid)
        .where('startedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .where('startedAt', isLessThan: Timestamp.fromDate(endOfWeek))
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PomodoroSessionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Tüm oturumları dinler (başlangıç tarihine göre azalan)
  Stream<List<PomodoroSessionModel>> watchAllSessions(String uid) {
    return _sessionsCol(uid)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PomodoroSessionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Toplam istatistikleri getirir
  Future<Map<String, dynamic>> getTotalStats(String uid) async {
    final snap = await _sessionsCol(uid).get();
    int totalSessions = snap.docs.length;
    int totalMinutes = 0;
    int totalXp = 0;

    for (final doc in snap.docs) {
      final data = doc.data();
      totalMinutes += (data['workMinutes'] as num?)?.toInt() ?? 0;
      totalXp += (data['xpEarned'] as num?)?.toInt() ?? 0;
    }

    return {
      'totalSessions': totalSessions,
      'totalMinutes': totalMinutes,
      'totalXp': totalXp,
    };
  }
}

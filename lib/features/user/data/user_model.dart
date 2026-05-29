import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final int streak;
  final DateTime? lastActiveDate;
  final String title;
  final Map<String, int> stats;
  final int totalQuestsCompleted;
  final int totalPomodoroSessions;
  final int totalMinutesFocused;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.level,
    required this.xp,
    required this.xpToNextLevel,
    required this.streak,
    this.lastActiveDate,
    required this.title,
    required this.stats,
    this.totalQuestsCompleted = 0,
    this.totalPomodoroSessions = 0,
    this.totalMinutesFocused = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final rawStats = (map['stats'] as Map<String, dynamic>?) ?? {};
    return UserModel(
      uid: map['uid'] as String,
      displayName: map['displayName'] as String? ?? 'Savaşçı',
      email: map['email'] as String? ?? '',
      level: (map['level'] as num?)?.toInt() ?? 1,
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      xpToNextLevel: (map['xpToNextLevel'] as num?)?.toInt() ?? 500,
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      lastActiveDate: (map['lastActiveDate'] as Timestamp?)?.toDate(),
      title: map['title'] as String? ?? 'Acemi Savaşçı',
      stats: rawStats.map((k, v) => MapEntry(k, (v as num).toInt())),
      totalQuestsCompleted: (map['totalQuestsCompleted'] as num?)?.toInt() ?? 0,
      totalPomodoroSessions: (map['totalPomodoroSessions'] as num?)?.toInt() ?? 0,
      totalMinutesFocused: (map['totalMinutesFocused'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'level': level,
        'xp': xp,
        'xpToNextLevel': xpToNextLevel,
        'streak': streak,
        'lastActiveDate': lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
        'title': title,
        'stats': stats,
        'totalQuestsCompleted': totalQuestsCompleted,
        'totalPomodoroSessions': totalPomodoroSessions,
        'totalMinutesFocused': totalMinutesFocused,
      };

  UserModel copyWith({
    int? level,
    int? xp,
    int? xpToNextLevel,
    int? streak,
    DateTime? lastActiveDate,
    String? title,
    Map<String, int>? stats,
    int? totalQuestsCompleted,
    int? totalPomodoroSessions,
    int? totalMinutesFocused,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName,
      email: email,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      streak: streak ?? this.streak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      title: title ?? this.title,
      stats: stats ?? this.stats,
      totalQuestsCompleted: totalQuestsCompleted ?? this.totalQuestsCompleted,
      totalPomodoroSessions: totalPomodoroSessions ?? this.totalPomodoroSessions,
      totalMinutesFocused: totalMinutesFocused ?? this.totalMinutesFocused,
    );
  }
}

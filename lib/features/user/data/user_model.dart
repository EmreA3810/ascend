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
  final List<String> focusAreas;
  final List<String> unlockedItems;
  final Map<String, String> equippedItems;
  final Map<String, int> chestsEarned;
  final int gold;

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
    this.focusAreas = const [],
    this.unlockedItems = const [],
    this.equippedItems = const {},
    this.chestsEarned = const {},
    this.gold = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final rawStats = (map['stats'] as Map<String, dynamic>?) ?? {};
    final rawEquipped = (map['equippedItems'] as Map<String, dynamic>?) ?? {};
    final rawChests = (map['chestsEarned'] as Map<String, dynamic>?) ?? {};

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
      focusAreas: List<String>.from(map['focusAreas'] ?? const []),
      unlockedItems: List<String>.from(map['unlockedItems'] ?? const []),
      equippedItems: rawEquipped.map((k, v) => MapEntry(k, v as String)),
      chestsEarned: rawChests.map((k, v) => MapEntry(k, (v as num).toInt())),
      gold: (map['gold'] as num?)?.toInt() ?? 0,
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
        'focusAreas': focusAreas,
        'unlockedItems': unlockedItems,
        'equippedItems': equippedItems,
        'chestsEarned': chestsEarned,
        'gold': gold,
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
    List<String>? focusAreas,
    List<String>? unlockedItems,
    Map<String, String>? equippedItems,
    Map<String, int>? chestsEarned,
    int? gold,
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
      focusAreas: focusAreas ?? this.focusAreas,
      unlockedItems: unlockedItems ?? this.unlockedItems,
      equippedItems: equippedItems ?? this.equippedItems,
      chestsEarned: chestsEarned ?? this.chestsEarned,
      gold: gold ?? this.gold,
    );
  }
}

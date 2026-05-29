import 'package:cloud_firestore/cloud_firestore.dart';

class PomodoroSessionModel {
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final int workMinutes;
  final int breakMinutes;
  final int xpEarned;
  final bool completed;

  const PomodoroSessionModel({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.workMinutes,
    required this.breakMinutes,
    required this.xpEarned,
    required this.completed,
  });

  factory PomodoroSessionModel.fromMap(Map<String, dynamic> map, String docId) {
    return PomodoroSessionModel(
      id: docId,
      startedAt: (map['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endedAt: (map['endedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      workMinutes: (map['workMinutes'] as num?)?.toInt() ?? 0,
      breakMinutes: (map['breakMinutes'] as num?)?.toInt() ?? 0,
      xpEarned: (map['xpEarned'] as num?)?.toInt() ?? 0,
      completed: map['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'startedAt': Timestamp.fromDate(startedAt),
        'endedAt': Timestamp.fromDate(endedAt),
        'workMinutes': workMinutes,
        'breakMinutes': breakMinutes,
        'xpEarned': xpEarned,
        'completed': completed,
      };

  PomodoroSessionModel copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? endedAt,
    int? workMinutes,
    int? breakMinutes,
    int? xpEarned,
    bool? completed,
  }) {
    return PomodoroSessionModel(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      workMinutes: workMinutes ?? this.workMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      xpEarned: xpEarned ?? this.xpEarned,
      completed: completed ?? this.completed,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String icon; // emoji string
  final int requiredValue;
  final int currentValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int xpReward;
  final String category; // 'streak', 'pomodoro', 'quest', 'level', 'stat'

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredValue,
    required this.currentValue,
    required this.isUnlocked,
    this.unlockedAt,
    required this.xpReward,
    required this.category,
  });

  factory AchievementModel.fromMap(Map<String, dynamic> map, String docId) {
    return AchievementModel(
      id: docId,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      icon: map['icon'] as String? ?? '⭐',
      requiredValue: (map['requiredValue'] as num?)?.toInt() ?? 0,
      currentValue: (map['currentValue'] as num?)?.toInt() ?? 0,
      isUnlocked: map['isUnlocked'] as bool? ?? false,
      unlockedAt: (map['unlockedAt'] as Timestamp?)?.toDate(),
      xpReward: (map['xpReward'] as num?)?.toInt() ?? 0,
      category: map['category'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'icon': icon,
        'requiredValue': requiredValue,
        'currentValue': currentValue,
        'isUnlocked': isUnlocked,
        'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
        'xpReward': xpReward,
        'category': category,
      };

  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    int? requiredValue,
    int? currentValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? xpReward,
    String? category,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      requiredValue: requiredValue ?? this.requiredValue,
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      xpReward: xpReward ?? this.xpReward,
      category: category ?? this.category,
    );
  }
}

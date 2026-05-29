import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class QuestModel {
  final String id;
  final String title;
  final int xpReward;
  final String category; // 'daily', 'weekly', 'custom'
  final String iconName; // Firestore'da string olarak saklanır
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String statBoost; // 'focus', 'energy', 'knowledge', 'strength'
  final double progress; // 0.0 - 1.0

  const QuestModel({
    required this.id,
    required this.title,
    required this.xpReward,
    required this.category,
    required this.iconName,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
    required this.statBoost,
    required this.progress,
  });

  factory QuestModel.fromMap(Map<String, dynamic> map, String docId) {
    return QuestModel(
      id: docId,
      title: map['title'] as String? ?? '',
      xpReward: (map['xpReward'] as num?)?.toInt() ?? 0,
      category: map['category'] as String? ?? 'daily',
      iconName: map['iconName'] as String? ?? 'star',
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      statBoost: map['statBoost'] as String? ?? 'focus',
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'xpReward': xpReward,
        'category': category,
        'iconName': iconName,
        'isCompleted': isCompleted,
        'createdAt': Timestamp.fromDate(createdAt),
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'statBoost': statBoost,
        'progress': progress,
      };

  QuestModel copyWith({
    String? id,
    String? title,
    int? xpReward,
    String? category,
    String? iconName,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    String? statBoost,
    double? progress,
  }) {
    return QuestModel(
      id: id ?? this.id,
      title: title ?? this.title,
      xpReward: xpReward ?? this.xpReward,
      category: category ?? this.category,
      iconName: iconName ?? this.iconName,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      statBoost: statBoost ?? this.statBoost,
      progress: progress ?? this.progress,
    );
  }

  /// String icon adını IconData'ya çevirir
  static IconData iconFromName(String name) {
    const map = <String, IconData>{
      'school': Icons.school,
      'fitness_center': Icons.fitness_center,
      'menu_book': Icons.menu_book,
      'timer': Icons.timer,
      'water_drop': Icons.water_drop,
      'star': Icons.star,
      'check_circle': Icons.check_circle,
      'bolt': Icons.bolt,
      'local_fire_department': Icons.local_fire_department,
      'emoji_events': Icons.emoji_events,
      'psychology': Icons.psychology,
      'self_improvement': Icons.self_improvement,
      'work': Icons.work,
      'design_services': Icons.design_services,
    };
    return map[name] ?? Icons.star;
  }
}

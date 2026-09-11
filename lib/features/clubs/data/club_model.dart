import 'package:cloud_firestore/cloud_firestore.dart';

class ClubModel {
  final String id;
  final String name;
  final String tag;
  final String description;
  final String iconEmoji;
  final String creatorUid;
  final String creatorName;
  final String inviteCode;
  final List<String> memberUids;
  final int totalWeeklyXp;
  final DateTime createdAt;

  const ClubModel({
    required this.id,
    required this.name,
    required this.tag,
    required this.description,
    required this.iconEmoji,
    required this.creatorUid,
    required this.creatorName,
    required this.inviteCode,
    required this.memberUids,
    this.totalWeeklyXp = 0,
    required this.createdAt,
  });

  factory ClubModel.fromMap(Map<String, dynamic> map, String docId) {
    return ClubModel(
      id: docId,
      name: map['name'] as String? ?? 'Kulüp',
      tag: map['tag'] as String? ?? 'ASC',
      description: map['description'] as String? ?? '',
      iconEmoji: map['iconEmoji'] as String? ?? '⚔️',
      creatorUid: map['creatorUid'] as String? ?? '',
      creatorName: map['creatorName'] as String? ?? 'Savaşçı',
      inviteCode: map['inviteCode'] as String? ?? '',
      memberUids: List<String>.from(map['memberUids'] ?? const []),
      totalWeeklyXp: (map['totalWeeklyXp'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'tag': tag,
        'description': description,
        'iconEmoji': iconEmoji,
        'creatorUid': creatorUid,
        'creatorName': creatorName,
        'inviteCode': inviteCode,
        'memberUids': memberUids,
        'totalWeeklyXp': totalWeeklyXp,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  ClubModel copyWith({
    String? name,
    String? tag,
    String? description,
    String? iconEmoji,
    String? creatorUid,
    String? creatorName,
    String? inviteCode,
    List<String>? memberUids,
    int? totalWeeklyXp,
    DateTime? createdAt,
  }) {
    return ClubModel(
      id: id,
      name: name ?? this.name,
      tag: tag ?? this.tag,
      description: description ?? this.description,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      creatorUid: creatorUid ?? this.creatorUid,
      creatorName: creatorName ?? this.creatorName,
      inviteCode: inviteCode ?? this.inviteCode,
      memberUids: memberUids ?? this.memberUids,
      totalWeeklyXp: totalWeeklyXp ?? this.totalWeeklyXp,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'club_model.dart';
import '../../user/data/user_model.dart';

class ClubRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _clubsRef => _db.collection('clubs');
  CollectionReference<Map<String, dynamic>> get _usersRef => _db.collection('users');

  /// 6 Haneli rastgele ve havalı kulüp davet kodu üret (Örn: ASC794)
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    final randomPart = List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'ASC$randomPart';
  }

  /// Yeni Kulüp Oluştur
  Future<ClubModel> createClub({
    required String uid,
    required String userName,
    required String name,
    required String tag,
    required String description,
    required String iconEmoji,
  }) async {
    final cleanTag = tag.trim().toUpperCase();
    final inviteCode = _generateInviteCode();

    final docRef = _clubsRef.doc();
    final club = ClubModel(
      id: docRef.id,
      name: name.trim(),
      tag: cleanTag,
      description: description.trim(),
      iconEmoji: iconEmoji.isEmpty ? '⚔️' : iconEmoji,
      creatorUid: uid,
      creatorName: userName,
      inviteCode: inviteCode,
      memberUids: [uid],
      totalWeeklyXp: 0,
      createdAt: DateTime.now(),
    );

    await docRef.set(club.toMap());

    // Kullanıcının profilini kulüp bilgisiyle güncelle
    await _usersRef.doc(uid).update({
      'clubId': docRef.id,
      'clubName': club.name,
      'clubTag': club.tag,
    });

    return club;
  }

  /// Davet Kodu ile Kulübe Katıl
  Future<ClubModel?> joinClubByCode({
    required String uid,
    required String inviteCode,
  }) async {
    final cleanCode = inviteCode.trim().toUpperCase();
    final query = await _clubsRef.where('inviteCode', isEqualTo: cleanCode).limit(1).get();

    if (query.docs.isEmpty) {
      return null;
    }

    final doc = query.docs.first;
    final club = ClubModel.fromMap(doc.data(), doc.id);

    if (!club.memberUids.contains(uid)) {
      await doc.reference.update({
        'memberUids': FieldValue.arrayUnion([uid]),
      });
    }

    await _usersRef.doc(uid).update({
      'clubId': club.id,
      'clubName': club.name,
      'clubTag': club.tag,
    });

    return club.copyWith(
      memberUids: [...club.memberUids, if (!club.memberUids.contains(uid)) uid],
    );
  }

  /// Kulüpten Ayrıl
  Future<void> leaveClub({
    required String uid,
    required String clubId,
  }) async {
    final docRef = _clubsRef.doc(clubId);
    final snap = await docRef.get();

    if (snap.exists && snap.data() != null) {
      final club = ClubModel.fromMap(snap.data()!, snap.id);
      final remainingMembers = club.memberUids.where((id) => id != uid).toList();

      if (remainingMembers.isEmpty) {
        await docRef.delete();
      } else {
        await docRef.update({
          'memberUids': FieldValue.arrayRemove([uid]),
        });
      }
    }

    await _usersRef.doc(uid).update({
      'clubId': FieldValue.delete(),
      'clubName': FieldValue.delete(),
      'clubTag': FieldValue.delete(),
    });
  }

  /// Belirli bir kulübü anlık izle
  Stream<ClubModel?> watchClub(String clubId) {
    return _clubsRef.doc(clubId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return ClubModel.fromMap(snap.data()!, snap.id);
    });
  }

  /// Kulüp üyelerini canlı izle ve haftalık XP'ye göre sırala
  Stream<List<UserModel>> watchClubMembers(List<String> memberUids) {
    if (memberUids.isEmpty) {
      return Stream.value([]);
    }

    return _usersRef.snapshots().map((snap) {
      final members = snap.docs
          .map((d) => UserModel.fromMap(d.data()))
          .where((u) => memberUids.contains(u.uid))
          .toList();

      members.sort((a, b) {
        final cmp = b.weeklyXp.compareTo(a.weeklyXp);
        if (cmp != 0) return cmp;
        return b.xp.compareTo(a.xp);
      });
      return members;
    });
  }

  /// Kulüp Bilgilerini Güncelle (Yalnızca Kurucu Düzenleyebilir)
  Future<void> updateClubSettings({
    required String clubId,
    required String name,
    required String tag,
    required String description,
    required String iconEmoji,
    required String currentUserId,
  }) async {
    final cleanTag = tag.trim().toUpperCase();
    final cleanName = name.trim();
    final cleanDesc = description.trim();

    await _clubsRef.doc(clubId).update({
      'name': cleanName,
      'tag': cleanTag,
      'description': cleanDesc,
      'iconEmoji': iconEmoji.isEmpty ? '⚔️' : iconEmoji,
    });

    // Kurucunun kendi profilindeki kulüp ad ve etiketini anında senkronize et
    await _usersRef.doc(currentUserId).update({
      'clubName': cleanName,
      'clubTag': cleanTag,
    });
  }
}

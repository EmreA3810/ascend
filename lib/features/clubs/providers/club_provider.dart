import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/club_model.dart';
import '../data/club_repository.dart';
import '../../user/providers/user_provider.dart';
import '../../user/data/user_model.dart';

final clubRepositoryProvider = Provider<ClubRepository>((ref) {
  return ClubRepository();
});

/// Kullanıcının dahil olduğu kulübü izleyen akış
final userClubProvider = StreamProvider<ClubModel?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null || user.clubId == null || user.clubId!.isEmpty) {
    return Stream.value(null);
  }
  return ref.read(clubRepositoryProvider).watchClub(user.clubId!);
});

/// Kulüp üyelerinin canlı sıralaması
final clubMembersProvider = StreamProvider<List<UserModel>>((ref) {
  final clubAsync = ref.watch(userClubProvider);
  final club = clubAsync.value;
  if (club == null || club.memberUids.isEmpty) {
    return Stream.value([]);
  }
  return ref.read(clubRepositoryProvider).watchClubMembers(club.memberUids);
});

/// Tüm gerçek kayıtlı kullanıcıların canlı lig akışı
final liveAllUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.read(userRepositoryProvider).watchLiveUsers();
});

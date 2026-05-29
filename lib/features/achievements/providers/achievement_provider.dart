import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../user/providers/user_provider.dart';
import '../data/achievement_repository.dart';
import '../data/achievement_model.dart';

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  final userRepo = ref.read(userRepositoryProvider);
  return AchievementRepository(userRepo);
});

final userAchievementsProvider = StreamProvider<List<AchievementModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
    data: (user) {
      if (user == null) return const Stream.empty();
      return ref.read(achievementRepositoryProvider).watchAchievements(user.uid);
    },
  );
});

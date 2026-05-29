import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../user/providers/user_provider.dart';
import '../data/quest_repository.dart';
import '../data/quest_model.dart';

final questRepositoryProvider = Provider<QuestRepository>((ref) {
  final userRepo = ref.read(userRepositoryProvider);
  return QuestRepository(userRepo);
});

final dailyQuestsProvider = StreamProvider<List<QuestModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
    data: (user) {
      if (user == null) return const Stream.empty();
      return ref.read(questRepositoryProvider).watchDailyQuests(user.uid);
    },
  );
});

final weeklyQuestsProvider = StreamProvider<List<QuestModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
    data: (user) {
      if (user == null) return const Stream.empty();
      return ref.read(questRepositoryProvider).watchWeeklyQuests(user.uid);
    },
  );
});

final customQuestsProvider = StreamProvider<List<QuestModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
    data: (user) {
      if (user == null) return const Stream.empty();
      return ref.read(questRepositoryProvider).watchCustomQuests(user.uid);
    },
  );
});

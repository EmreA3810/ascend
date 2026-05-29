import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../user/providers/user_provider.dart';
import '../data/pomodoro_repository.dart';
import '../data/pomodoro_session_model.dart';

final pomodoroRepositoryProvider = Provider<PomodoroRepository>((ref) {
  final userRepo = ref.read(userRepositoryProvider);
  return PomodoroRepository(userRepo);
});

final todaySessionsProvider = StreamProvider<List<PomodoroSessionModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
    data: (user) {
      if (user == null) return const Stream.empty();
      return ref.read(pomodoroRepositoryProvider).watchTodaySessions(user.uid);
    },
  );
});

final weekSessionsProvider = StreamProvider<List<PomodoroSessionModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
    data: (user) {
      if (user == null) return const Stream.empty();
      return ref.read(pomodoroRepositoryProvider).watchWeekSessions(user.uid);
    },
  );
});

final allSessionsProvider = StreamProvider<List<PomodoroSessionModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
    data: (user) {
      if (user == null) return const Stream.empty();
      return ref.read(pomodoroRepositoryProvider).watchAllSessions(user.uid);
    },
  );
});

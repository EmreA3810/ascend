import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/user_repository.dart';
import '../data/user_model.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
    data: (user) {
      if (user == null) return const Stream.empty();
      return ref.read(userRepositoryProvider).watchUser(user.uid);
    },
  );
});

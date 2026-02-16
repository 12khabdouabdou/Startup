import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/app_user.dart';
import '../../profile/repositories/profile_repository.dart';
import '../../../core/providers/auth_provider.dart';

final userDocProvider = StreamProvider.autoDispose<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(profileRepositoryProvider).getUser(user.id);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

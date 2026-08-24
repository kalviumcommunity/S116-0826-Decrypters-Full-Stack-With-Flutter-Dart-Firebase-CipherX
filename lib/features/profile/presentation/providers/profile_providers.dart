import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../domain/entities/user_profile.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository();
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  final repository = ref.watch(userProfileRepositoryProvider);

  if (authUser == null) {
    return Stream.value(null);
  }

  return repository.streamUserProfile(authUser.uid);
});

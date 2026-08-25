import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../identity/presentation/providers/identity_providers.dart';
import '../../data/datasources/firebase_guard_data_source.dart';
import '../../data/repositories/guard_repository_impl.dart';
import '../../domain/entities/guard.dart';
import '../../domain/repositories/guard_repository.dart';

final firebaseGuardDataSourceProvider = Provider<FirebaseGuardDataSource>((
  ref,
) {
  final firestore = ref.watch(cloudFirestoreProvider);
  return FirebaseGuardDataSource(firestore: firestore);
});

final guardRepositoryProvider = Provider<GuardRepository>((ref) {
  final dataSource = ref.watch(firebaseGuardDataSourceProvider);
  return GuardRepositoryImpl(dataSource: dataSource);
});

final guardsStreamProvider = StreamProvider.autoDispose<List<Guard>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null) {
    return const Stream.empty();
  }

  final repository = ref.watch(guardRepositoryProvider);
  return repository.watchGuards(profile.organizationId);
});

class GuardController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> createGuard(Guard guard) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(guardRepositoryProvider);
      await repository.createGuard(guard);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updateGuard(Guard guard) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(guardRepositoryProvider);
      await repository.updateGuard(guard);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updateGuardStatus({
    required String organizationId,
    required String guardId,
    required GuardStatus status,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(guardRepositoryProvider);
      await repository.updateGuardStatus(
        organizationId: organizationId,
        guardId: guardId,
        status: status,
      );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final guardControllerProvider =
    AutoDisposeAsyncNotifierProvider<GuardController, void>(() {
      return GuardController();
    });

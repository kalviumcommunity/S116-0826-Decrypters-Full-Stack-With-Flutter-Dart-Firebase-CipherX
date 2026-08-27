import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../identity/presentation/providers/identity_providers.dart';
import '../../data/datasources/firebase_shift_data_source.dart';
import '../../data/repositories/shift_repository_impl.dart';
import '../../domain/entities/shift.dart';
import '../../domain/repositories/shift_repository.dart';
import '../../domain/validators/shift_validator.dart';

import '../../../guards/presentation/providers/guard_providers.dart';
import '../../../sites/presentation/providers/site_providers.dart';

final firebaseShiftDataSourceProvider = Provider<FirebaseShiftDataSource>((
  ref,
) {
  final firestore = ref.watch(cloudFirestoreProvider);
  return FirebaseShiftDataSource(firestore: firestore);
});

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  final dataSource = ref.watch(firebaseShiftDataSourceProvider);
  final guardRepository = ref.watch(guardRepositoryProvider);
  final siteRepository = ref.watch(siteRepositoryProvider);
  return ShiftRepositoryImpl(
    dataSource: dataSource,
    guardRepository: guardRepository,
    siteRepository: siteRepository,
  );
});

final shiftsStreamProvider = StreamProvider.autoDispose<List<Shift>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null) {
    return const Stream.empty();
  }

  final repository = ref.watch(shiftRepositoryProvider);
  return repository.watchShifts(profile.organizationId);
});

class ShiftCreationController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> createShift(Shift shift) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();

    try {
      ShiftValidator.validate(
        guardId: shift.guardId,
        siteId: shift.siteId,
        date: DateTime.tryParse(shift.shiftDate),
        startTime: shift.startTime,
        endTime: shift.endTime,
      );

      final repository = ref.read(shiftRepositoryProvider);
      await repository.createShift(shift);

      ref.invalidate(shiftsStreamProvider);

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final shiftCreationControllerProvider =
    AutoDisposeAsyncNotifierProvider<ShiftCreationController, void>(() {
  return ShiftCreationController();
});

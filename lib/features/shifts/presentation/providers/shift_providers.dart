import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../identity/presentation/providers/identity_providers.dart';
import '../../data/datasources/firebase_shift_data_source.dart';
import '../../data/repositories/shift_repository_impl.dart';
import '../../domain/entities/shift.dart';
import '../../domain/repositories/shift_repository.dart';
import '../../domain/validators/shift_validator.dart';

final firebaseShiftDataSourceProvider = Provider<FirebaseShiftDataSource>((
  ref,
) {
  final firestore = ref.watch(cloudFirestoreProvider);
  return FirebaseShiftDataSource(firestore: firestore);
});

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  final dataSource = ref.watch(firebaseShiftDataSourceProvider);
  return ShiftRepositoryImpl(dataSource: dataSource);
});

final shiftsStreamProvider =
    StreamProvider.autoDispose<List<Shift>>((ref) async* {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null) {
    yield const [];
    return;
  }

  final repository = ref.watch(shiftRepositoryProvider);
  final shifts =
      await repository.getShiftsByOrganization(profile.organizationId);
  yield shifts;
});

class ShiftCreationController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> createShift(Shift shift) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();

    try {
      final tempShift = shift.shiftId.isEmpty
          ? shift.copyWith(shiftId: 'temp_create_id')
          : shift;
      ShiftValidator.validate(tempShift);

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

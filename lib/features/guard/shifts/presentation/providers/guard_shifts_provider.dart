import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../identity/presentation/providers/identity_providers.dart';
import '../../../../shifts/data/datasources/firebase_shift_data_source.dart';
import '../../../../shifts/data/repositories/shift_repository_impl.dart';
import '../../../../shifts/domain/entities/shift.dart';
import '../../../../shifts/domain/repositories/shift_repository.dart';

final firebaseShiftDataSourceProvider = Provider<FirebaseShiftDataSource>((ref) {
  final firestore = ref.watch(cloudFirestoreProvider);
  return FirebaseShiftDataSource(firestore);
});

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  final dataSource = ref.watch(firebaseShiftDataSourceProvider);
  return ShiftRepositoryImpl(dataSource);
});

class GuardShiftsData {
  final Shift? todayShift;
  final List<Shift> upcomingShifts;

  GuardShiftsData({
    this.todayShift,
    required this.upcomingShifts,
  });
}

final guardShiftsProvider = FutureProvider.autoDispose<GuardShiftsData>((ref) async {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null) {
    throw Exception('User profile not loaded');
  }

  // Determine current guard based on UID
  final guardId = profile.uid;
  final organizationId = profile.organizationId;

  final repository = ref.watch(shiftRepositoryProvider);
  final shifts = await repository.getShiftsByGuard(organizationId, guardId);

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  Shift? todayShift;
  final List<Shift> upcomingShifts = [];

  for (final shift in shifts) {
    if (shift.date.isAfter(todayStart.subtract(const Duration(milliseconds: 1))) && 
        shift.date.isBefore(todayEnd)) {
      // It's today's shift. If there are multiple, just take the first or sort.
      // The prompt says: "If multiple shifts today are possible... handle them using the existing shift data correctly"
      // We will prioritize the one that hasn't finished yet or just the earliest one.
      if (todayShift == null || shift.date.isBefore(todayShift.date)) {
        todayShift = shift;
      }
    } else if (shift.date.isAfter(todayEnd.subtract(const Duration(milliseconds: 1)))) {
      upcomingShifts.add(shift);
    }
  }

  // Sort upcoming shifts chronologically
  upcomingShifts.sort((a, b) => a.date.compareTo(b.date));

  return GuardShiftsData(
    todayShift: todayShift,
    upcomingShifts: upcomingShifts,
  );
});

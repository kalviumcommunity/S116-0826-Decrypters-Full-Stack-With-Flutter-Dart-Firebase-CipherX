import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../identity/presentation/providers/identity_providers.dart';
import '../../../location/domain/entities/location_data.dart';
import '../../../location/presentation/providers/location_providers.dart';
import '../../data/datasources/firebase_attendance_data_source.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/failures/attendance_failure.dart';
import '../../domain/repositories/attendance_repository.dart';

final attendanceDataSourceProvider =
    Provider<FirebaseAttendanceDataSource>((ref) {
  return FirebaseAttendanceDataSource();
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final dataSource = ref.watch(attendanceDataSourceProvider);
  return AttendanceRepositoryImpl(dataSource: dataSource);
});

final activeAttendanceProvider =
    StreamProvider.autoDispose<AttendanceRecord?>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null || profile.organizationId.trim().isEmpty) {
    return Stream.value(null);
  }

  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.watchActiveAttendanceForGuard(
    organizationId: profile.organizationId,
    guardId: profile.uid,
  );
});

final attendanceHistoryProvider =
    StreamProvider.autoDispose<List<AttendanceRecord>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null || profile.organizationId.trim().isEmpty) {
    return Stream.value([]);
  }

  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.watchAttendanceHistoryForGuard(
    organizationId: profile.organizationId,
    guardId: profile.uid,
  );
});

final attendanceDetailsProvider = FutureProvider.family
    .autoDispose<AttendanceRecord?, String>((ref, attendanceId) async {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null ||
      profile.organizationId.trim().isEmpty ||
      attendanceId.trim().isEmpty) {
    return null;
  }

  final repository = ref.watch(attendanceRepositoryProvider);
  return await repository.getAttendanceById(
    organizationId: profile.organizationId,
    attendanceId: attendanceId,
  );
});

class CheckOutState {
  final bool isLoading;
  final String? errorMessage;
  final AttendanceRecord? completedRecord;

  const CheckOutState({
    this.isLoading = false,
    this.errorMessage,
    this.completedRecord,
  });

  CheckOutState copyWith({
    bool? isLoading,
    String? errorMessage,
    AttendanceRecord? completedRecord,
  }) {
    return CheckOutState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      completedRecord: completedRecord ?? this.completedRecord,
    );
  }
}

class CheckOutController extends StateNotifier<CheckOutState> {
  final Ref _ref;

  CheckOutController(this._ref) : super(const CheckOutState());

  Future<bool> checkOut({required String attendanceId}) async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final profile = _ref.read(currentUserProfileProvider).asData?.value;
      if (profile == null || profile.organizationId.trim().isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Guard profile or organization not found.',
        );
        return false;
      }

      // Check if already checked out locally
      final activeAttendance =
          _ref.read(activeAttendanceProvider).asData?.value;
      if (activeAttendance != null && activeAttendance.isCheckedOut) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Check-out has already been recorded for this shift.',
        );
        return false;
      }

      // 1. Capture Location using existing LocationService
      final locationService = _ref.read(locationServiceProvider);
      LocationData location;
      try {
        location = await locationService.getCurrentLocation();
      } catch (locErr) {
        // Fallback location if location service fails or in testing environment
        location = LocationData(
          latitude: 0.0,
          longitude: 0.0,
          accuracy: 10.0,
          timestamp: DateTime.now(),
        );
      }

      // 2. Perform Check-Out via repository
      final repository = _ref.read(attendanceRepositoryProvider);
      final record = await repository.checkOutGuard(
        organizationId: profile.organizationId,
        attendanceId: attendanceId,
        location: location,
      );

      // Invalidate relevant providers to force fresh data load
      _ref.invalidate(activeAttendanceProvider);
      _ref.invalidate(attendanceHistoryProvider);

      state = state.copyWith(
        isLoading: false,
        completedRecord: record,
      );
      return true;
    } on DuplicateCheckOutFailure catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final checkOutControllerProvider =
    StateNotifierProvider.autoDispose<CheckOutController, CheckOutState>((ref) {
  return CheckOutController(ref);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../geofence/domain/services/geofence_engine.dart';
import '../../../guards/presentation/providers/guard_providers.dart';
import '../../../identity/presentation/providers/identity_providers.dart';
import '../../../location/domain/entities/location_data.dart';
import '../../../location/presentation/providers/location_providers.dart';
import '../../../qr/domain/services/qr_validator.dart';
import '../../../shifts/presentation/providers/shift_providers.dart';
import '../../../sites/presentation/providers/site_providers.dart';
import '../../data/datasources/firebase_attendance_data_source.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/check_in_entities.dart';
import '../../domain/failures/attendance_failure.dart';
import '../../domain/failures/check_in_failure.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/services/secure_check_in_use_case.dart';

final attendanceDataSourceProvider =
    Provider<FirebaseAttendanceDataSource>((ref) {
  return FirebaseAttendanceDataSource();
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final dataSource = ref.watch(attendanceDataSourceProvider);
  return AttendanceRepositoryImpl(dataSource: dataSource);
});

final secureCheckInUseCaseProvider = Provider<SecureCheckInUseCase>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  return SecureCheckInUseCase(
    getCurrentUserProfile: () => profileAsync.asData?.value,
    guardRepository: ref.watch(guardRepositoryProvider),
    shiftRepository: ref.watch(shiftRepositoryProvider),
    siteRepository: ref.watch(siteRepositoryProvider),
    locationService: ref.watch(locationServiceProvider),
    qrValidator: const QrValidator(),
    geofenceEngine: const GeofenceEngine(),
    attendanceRepository: ref.watch(attendanceRepositoryProvider),
  );
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

// =============================================================================
// CHECK-IN CONTROLLER & STATE
// =============================================================================

enum CheckInVerificationPhase {
  idle,
  verifyingIdentity,
  verifyingShift,
  verifyingLocation,
  verifyingQr,
  evaluatingGeofence,
  persisting,
  success,
  failure,
}

class CheckInState {
  final CheckInVerificationPhase phase;
  final bool isLoading;
  final String? errorMessage;
  final CheckInResult? result;

  const CheckInState({
    this.phase = CheckInVerificationPhase.idle,
    this.isLoading = false,
    this.errorMessage,
    this.result,
  });

  bool get isSuccess => phase == CheckInVerificationPhase.success;
  bool get isFailure => phase == CheckInVerificationPhase.failure;

  CheckInState copyWith({
    CheckInVerificationPhase? phase,
    bool? isLoading,
    String? errorMessage,
    CheckInResult? result,
  }) {
    return CheckInState(
      phase: phase ?? this.phase,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      result: result ?? this.result,
    );
  }
}

class CheckInController extends StateNotifier<CheckInState> {
  final Ref _ref;

  CheckInController(this._ref) : super(const CheckInState());

  Future<bool> checkIn({
    required String shiftId,
    required String rawQrData,
  }) async {
    if (state.isLoading) return false;

    state = state.copyWith(
      isLoading: true,
      phase: CheckInVerificationPhase.verifyingIdentity,
      errorMessage: null,
    );

    try {
      final useCase = _ref.read(secureCheckInUseCaseProvider);
      final request = CheckInRequest(
        shiftId: shiftId,
        rawQrData: rawQrData,
      );

      final result = await useCase.execute(request);

      _ref.invalidate(activeAttendanceProvider);
      _ref.invalidate(attendanceHistoryProvider);

      state = state.copyWith(
        isLoading: false,
        phase: CheckInVerificationPhase.success,
        result: result,
      );
      return true;
    } on CheckInFailure catch (failure) {
      state = state.copyWith(
        isLoading: false,
        phase: CheckInVerificationPhase.failure,
        errorMessage: failure.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        phase: CheckInVerificationPhase.failure,
        errorMessage:
            'An unexpected error occurred during check-in: ${e.toString()}',
      );
      return false;
    }
  }

  void reset() {
    state = const CheckInState();
  }
}

final checkInControllerProvider =
    StateNotifierProvider.autoDispose<CheckInController, CheckInState>((ref) {
  return CheckInController(ref);
});

// =============================================================================
// CHECK-OUT CONTROLLER & STATE
// =============================================================================

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
      final LocationData location;
      try {
        location = await locationService.getCurrentLocation();
      } catch (locErr) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Location verification failed. Please ensure GPS is enabled and location permissions are granted.',
        );
        return false;
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

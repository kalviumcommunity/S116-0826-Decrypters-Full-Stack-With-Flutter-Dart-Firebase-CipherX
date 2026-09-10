import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../identity/presentation/providers/identity_providers.dart';
import '../../../location/presentation/providers/location_providers.dart';
import '../../data/datasources/firebase_incident_data_source.dart';
import '../../data/repositories/incident_repository_impl.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/incident_severity.dart';
import '../../domain/entities/incident_status.dart';
import '../../domain/failures/incident_failure.dart';
import '../../domain/repositories/incident_repository.dart';

final incidentDataSourceProvider = Provider<FirebaseIncidentDataSource>((ref) {
  final firestore = ref.watch(cloudFirestoreProvider);
  return FirebaseIncidentDataSource(firestore: firestore);
});

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  final dataSource = ref.watch(incidentDataSourceProvider);
  return IncidentRepositoryImpl(dataSource: dataSource);
});

final guardIncidentsProvider =
    StreamProvider.autoDispose<List<Incident>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null || profile.organizationId.trim().isEmpty) {
    return Stream.value([]);
  }

  final repository =
      ref.watch(incidentRepositoryProvider) as IncidentRepositoryImpl;
  return repository.watchIncidentsByReporter(
    organizationId: profile.organizationId,
    reportedBy: profile.uid,
  );
});

class IncidentReportState {
  final String type;
  final IncidentSeverity severity;
  final String description;
  final String? siteId;
  final double? latitude;
  final double? longitude;
  final bool isFetchingLocation;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  const IncidentReportState({
    this.type = 'Other',
    this.severity = IncidentSeverity.low,
    this.description = '',
    this.siteId,
    this.latitude,
    this.longitude,
    this.isFetchingLocation = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  IncidentReportState copyWith({
    String? type,
    IncidentSeverity? severity,
    String? description,
    String? siteId,
    double? latitude,
    double? longitude,
    bool? isFetchingLocation,
    bool? isSubmitting,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return IncidentReportState(
      type: type ?? this.type,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      siteId: siteId ?? this.siteId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isFetchingLocation: isFetchingLocation ?? this.isFetchingLocation,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class IncidentReportController extends StateNotifier<IncidentReportState> {
  final Ref _ref;

  IncidentReportController(this._ref) : super(const IncidentReportState()) {
    final active = _ref.read(activeAttendanceProvider).asData?.value;
    if (active != null && active.siteId.trim().isNotEmpty) {
      state = state.copyWith(siteId: active.siteId.trim());
    }
  }

  void initFromActiveAttendance(AttendanceRecord? record) {
    if (record != null &&
        record.siteId.trim().isNotEmpty &&
        state.siteId == null) {
      state = state.copyWith(siteId: record.siteId.trim());
    }
  }

  void setType(String type) {
    state = state.copyWith(type: type, errorMessage: null);
  }

  void setSeverity(IncidentSeverity severity) {
    state = state.copyWith(severity: severity, errorMessage: null);
  }

  void setDescription(String description) {
    state = state.copyWith(description: description, errorMessage: null);
  }

  void setSiteId(String? siteId) {
    state = state.copyWith(siteId: siteId, errorMessage: null);
  }

  Future<void> fetchCurrentLocation() async {
    if (state.isFetchingLocation) return;
    state = state.copyWith(isFetchingLocation: true, errorMessage: null);

    try {
      final locationService = _ref.read(locationServiceProvider);
      final loc = await locationService.getCurrentLocation();
      state = state.copyWith(
        latitude: loc.latitude,
        longitude: loc.longitude,
        isFetchingLocation: false,
      );
    } catch (e) {
      state = state.copyWith(
        isFetchingLocation: false,
        errorMessage:
            'Unable to acquire location fix. Location will be optional.',
      );
    }
  }

  Future<bool> submitIncident() async {
    if (state.isSubmitting) return false;

    if (state.description.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please enter a description of what happened.',
      );
      return false;
    }

    final activeAttendance = _ref.read(activeAttendanceProvider).asData?.value;
    final effectiveSiteId = (state.siteId?.trim().isNotEmpty == true)
        ? state.siteId!.trim()
        : (activeAttendance?.siteId.trim() ?? '');

    if (effectiveSiteId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please select or assign a site for this incident.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final profile = _ref.read(currentUserProfileProvider).asData?.value;
      if (profile == null || profile.organizationId.trim().isEmpty) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'Guard profile or organization context missing.',
        );
        return false;
      }

      double? lat = state.latitude;
      double? lng = state.longitude;

      if (lat == null || lng == null) {
        try {
          final locationService = _ref.read(locationServiceProvider);
          final loc = await locationService.getCurrentLocation();
          lat = loc.latitude;
          lng = loc.longitude;
        } catch (_) {
          lat = null;
          lng = null;
        }
      }

      final now = DateTime.now();
      final incident = Incident(
        incidentId: '',
        organizationId: profile.organizationId.trim(),
        reportedBy: profile.uid.trim(),
        siteId: effectiveSiteId,
        type: state.type.trim().isNotEmpty ? state.type.trim() : 'Other',
        severity: state.severity,
        description: state.description.trim(),
        latitude: lat,
        longitude: lng,
        status: IncidentStatus.open,
        createdAt: now,
        updatedAt: now,
      );

      final repository = _ref.read(incidentRepositoryProvider);
      await repository.createIncident(incident);

      _ref.invalidate(guardIncidentsProvider);

      state = state.copyWith(
        isSubmitting: false,
        isSuccess: true,
      );
      return true;
    } on IncidentFailure catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final incidentReportControllerProvider = StateNotifierProvider.autoDispose<
    IncidentReportController, IncidentReportState>((ref) {
  return IncidentReportController(ref);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../identity/presentation/providers/identity_providers.dart';
import '../../../location/presentation/providers/location_providers.dart';
import '../../data/datasources/firebase_incident_data_source.dart';
import '../../data/repositories/incident_repository_impl.dart';
import '../../domain/entities/incident.dart';
import '../../domain/failures/incident_failure.dart';
import '../../domain/repositories/incident_repository.dart';

final incidentDataSourceProvider = Provider<FirebaseIncidentDataSource>((ref) {
  return FirebaseIncidentDataSource();
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

  final repository = ref.watch(incidentRepositoryProvider);
  return repository.watchIncidentsByGuard(
    organizationId: profile.organizationId,
    guardId: profile.uid,
  );
});

class IncidentReportState {
  final IncidentType type;
  final IncidentSeverity severity;
  final String description;
  final String? siteId;
  final double? latitude;
  final double? longitude;
  final List<String> evidenceUrls;
  final bool isFetchingLocation;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  const IncidentReportState({
    this.type = IncidentType.other,
    this.severity = IncidentSeverity.low,
    this.description = '',
    this.siteId,
    this.latitude,
    this.longitude,
    this.evidenceUrls = const [],
    this.isFetchingLocation = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  IncidentReportState copyWith({
    IncidentType? type,
    IncidentSeverity? severity,
    String? description,
    String? siteId,
    double? latitude,
    double? longitude,
    List<String>? evidenceUrls,
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
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      isFetchingLocation: isFetchingLocation ?? this.isFetchingLocation,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class IncidentReportController extends StateNotifier<IncidentReportState> {
  final Ref _ref;

  IncidentReportController(this._ref) : super(const IncidentReportState());

  void setType(IncidentType type) {
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

  void addEvidenceUrl(String evidenceUrl) {
    if (evidenceUrl.trim().isEmpty) return;
    final updated = List<String>.from(state.evidenceUrls)
      ..add(evidenceUrl.trim());
    state = state.copyWith(evidenceUrls: updated, errorMessage: null);
  }

  void removeEvidenceUrl(int index) {
    if (index < 0 || index >= state.evidenceUrls.length) return;
    final updated = List<String>.from(state.evidenceUrls)..removeAt(index);
    state = state.copyWith(evidenceUrls: updated);
  }

  Future<void> fetchCurrentLocation() async {
    if (state.isFetchingLocation) return;
    state = state.copyWith(isFetchingLocation: true, errorMessage: null);

    try {
      final locationService = _ref.read(locationServiceProvider);
      final locationData = await locationService.getCurrentLocation();
      state = state.copyWith(
        latitude: locationData.latitude,
        longitude: locationData.longitude,
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
    // 1. Double submission prevention
    if (state.isSubmitting) return false;

    if (state.description.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please enter a description of what happened.',
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

      // Try acquiring location if not already fetched
      double? lat = state.latitude;
      double? lng = state.longitude;

      if (lat == null || lng == null) {
        try {
          final locationService = _ref.read(locationServiceProvider);
          final loc = await locationService.getCurrentLocation();
          lat = loc.latitude;
          lng = loc.longitude;
        } catch (_) {
          // Continue if location unavailable
        }
      }

      final incident = Incident(
        incidentId: '',
        organizationId: profile.organizationId,
        siteId: state.siteId ?? '',
        guardId: profile.uid,
        type: state.type,
        severity: state.severity,
        description: state.description.trim(),
        status: IncidentStatus.open,
        latitude: lat,
        longitude: lng,
        evidenceUrls: state.evidenceUrls,
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

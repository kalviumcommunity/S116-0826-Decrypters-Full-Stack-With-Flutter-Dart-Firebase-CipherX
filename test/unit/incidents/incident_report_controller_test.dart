import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/attendance/domain/entities/attendance_record.dart';
import 'package:cipher_x/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';
import 'package:cipher_x/features/identity/presentation/providers/identity_providers.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_severity.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_status.dart';
import 'package:cipher_x/features/incidents/domain/repositories/incident_repository.dart';
import 'package:cipher_x/features/incidents/presentation/providers/incident_providers.dart';
import 'package:cipher_x/features/location/domain/entities/location_data.dart';
import 'package:cipher_x/features/location/domain/entities/location_permission_state.dart';
import 'package:cipher_x/features/location/domain/services/location_service.dart';
import 'package:cipher_x/features/location/presentation/providers/location_providers.dart';

class FakeIncidentRepository implements IncidentRepository {
  final List<Incident> incidents = [];

  @override
  Future<Incident> createIncident(Incident incident) async {
    final created = incident.copyWith(
      incidentId: 'generated_${incidents.length + 1}',
    );
    incidents.add(created);
    return created;
  }

  @override
  Future<Incident?> getIncident({
    required String organizationId,
    required String incidentId,
  }) async =>
      null;

  @override
  Future<List<Incident>> getIncidentsByOrganization(
    String organizationId, {
    IncidentStatus? status,
    IncidentSeverity? severity,
    int? limit,
  }) async =>
      incidents;

  @override
  Stream<List<Incident>> watchIncidentsByOrganization(
    String organizationId, {
    IncidentStatus? status,
    IncidentSeverity? severity,
  }) =>
      Stream.value(incidents);

  @override
  Future<List<Incident>> getIncidentsBySite({
    required String organizationId,
    required String siteId,
    IncidentStatus? status,
  }) async =>
      incidents;

  @override
  Stream<List<Incident>> watchIncidentsBySite({
    required String organizationId,
    required String siteId,
    IncidentStatus? status,
  }) =>
      Stream.value(incidents);

  @override
  Future<List<Incident>> getIncidentsByReporter({
    required String organizationId,
    required String reportedBy,
  }) async =>
      incidents;

  @override
  Future<Incident> updateIncident(Incident incident) async => incident;

  @override
  Future<Incident> updateIncidentStatus({
    required String organizationId,
    required String incidentId,
    required IncidentStatus status,
    String? resolvedBy,
    DateTime? resolvedAt,
  }) async {
    return incidents.first;
  }
}

class FakeLocationService implements LocationService {
  final double lat;
  final double lng;
  final bool shouldThrow;

  FakeLocationService({
    this.lat = 18.5204,
    this.lng = 73.8567,
    this.shouldThrow = false,
  });

  @override
  Future<LocationData> getCurrentLocation({Duration? timeout}) async {
    if (shouldThrow) throw Exception('Location error');
    return LocationData(
      latitude: lat,
      longitude: lng,
      accuracy: 5.0,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermissionState> checkPermission() async =>
      LocationPermissionState.granted;

  @override
  Future<LocationPermissionState> requestPermission() async =>
      LocationPermissionState.granted;
}

void main() {
  late FakeIncidentRepository fakeRepo;
  late FakeLocationService fakeLocation;

  const testUser = UserProfile(
    uid: 'guard_123',
    email: 'guard@example.com',
    displayName: 'Test Guard',
    phone: '1234567890',
    role: UserRole.guard,
    organizationId: 'org_123',
  );

  setUp(() {
    fakeRepo = FakeIncidentRepository();
    fakeLocation = FakeLocationService();
  });

  ProviderContainer createContainer({
    UserProfile? profile = testUser,
    AttendanceRecord? activeAttendance,
    FakeLocationService? locationService,
  }) {
    return ProviderContainer(
      overrides: [
        currentUserProfileProvider.overrideWithValue(AsyncValue.data(profile)),
        activeAttendanceProvider
            .overrideWith((ref) => Stream.value(activeAttendance)),
        incidentRepositoryProvider.overrideWithValue(fakeRepo),
        locationServiceProvider
            .overrideWithValue(locationService ?? fakeLocation),
      ],
    );
  }

  group('IncidentReportController Tests', () {
    test('initial state has clean defaults and can populate active shift site',
        () {
      final activeRecord = AttendanceRecord(
        attendanceId: 'att_1',
        organizationId: 'org_123',
        guardId: 'guard_123',
        shiftId: 'shift_1',
        siteId: 'site_active_1',
        checkInTime: DateTime.utc(2026, 9, 10, 8, 0),
        verificationMethod: 'qr_gps_geofence',
      );

      final container = createContainer(activeAttendance: activeRecord);
      final controller =
          container.read(incidentReportControllerProvider.notifier);
      controller.initFromActiveAttendance(activeRecord);
      final state = container.read(incidentReportControllerProvider);

      expect(state.type, equals('Other'));
      expect(state.severity, equals(IncidentSeverity.low));
      expect(state.description, isEmpty);
      expect(state.siteId, equals('site_active_1'));
      expect(state.isSubmitting, isFalse);
    });

    test('state updates mutate fields correctly', () {
      final container = createContainer();
      final controller =
          container.read(incidentReportControllerProvider.notifier);

      controller.setType('Vandalism');
      controller.setSeverity(IncidentSeverity.critical);
      controller.setDescription('Graffiti on east wall.');
      controller.setSiteId('site_custom');

      final state = container.read(incidentReportControllerProvider);
      expect(state.type, equals('Vandalism'));
      expect(state.severity, equals(IncidentSeverity.critical));
      expect(state.description, equals('Graffiti on east wall.'));
      expect(state.siteId, equals('site_custom'));
    });

    test('fetchCurrentLocation acquires coordinates from location service',
        () async {
      final container = createContainer();
      final controller =
          container.read(incidentReportControllerProvider.notifier);

      await controller.fetchCurrentLocation();

      final state = container.read(incidentReportControllerProvider);
      expect(state.latitude, equals(18.5204));
      expect(state.longitude, equals(73.8567));
      expect(state.isFetchingLocation, isFalse);
    });

    test('submitIncident validates empty description', () async {
      final container = createContainer();
      final controller =
          container.read(incidentReportControllerProvider.notifier);

      controller.setDescription('   ');
      final result = await controller.submitIncident();

      expect(result, isFalse);
      expect(container.read(incidentReportControllerProvider).errorMessage,
          contains('description'));
    });

    test('submitIncident validates empty siteId', () async {
      final container = createContainer();
      final controller =
          container.read(incidentReportControllerProvider.notifier);

      controller.setDescription('Perimeter fence breached.');
      controller.setSiteId('');
      final result = await controller.submitIncident();

      expect(result, isFalse);
      expect(container.read(incidentReportControllerProvider).errorMessage,
          contains('site'));
    });

    test('submitIncident successfully creates incident and marks isSuccess',
        () async {
      final container = createContainer();
      final controller =
          container.read(incidentReportControllerProvider.notifier);

      controller.setType('Intrusion');
      controller.setSeverity(IncidentSeverity.high);
      controller.setSiteId('site_alpha');
      controller.setDescription('Unknown individual detected near gate 3.');

      final result = await controller.submitIncident();

      expect(result, isTrue);
      expect(
          container.read(incidentReportControllerProvider).isSuccess, isTrue);
      expect(fakeRepo.incidents.length, equals(1));
      expect(fakeRepo.incidents.first.reportedBy, equals('guard_123'));
      expect(fakeRepo.incidents.first.siteId, equals('site_alpha'));
      expect(fakeRepo.incidents.first.status, equals(IncidentStatus.open));
    });
  });
}

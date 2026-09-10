import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';
import 'package:cipher_x/features/identity/presentation/providers/identity_providers.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_severity.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_status.dart';
import 'package:cipher_x/features/incidents/domain/repositories/incident_repository.dart';
import 'package:cipher_x/features/incidents/presentation/providers/incident_providers.dart';
import 'package:cipher_x/features/incidents/presentation/screens/incident_list_screen.dart';
import 'package:cipher_x/features/incidents/presentation/screens/incident_report_screen.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';
import 'package:cipher_x/features/sites/presentation/providers/site_providers.dart';

class MockIncidentRepository implements IncidentRepository {
  List<Incident> incidents = [];

  @override
  Future<Incident> createIncident(Incident incident) async {
    incidents.add(incident);
    return incident;
  }

  @override
  Future<Incident?> getIncident(
          {required String organizationId, required String incidentId}) async =>
      null;

  @override
  Future<List<Incident>> getIncidentsByOrganization(String organizationId,
          {IncidentStatus? status,
          IncidentSeverity? severity,
          int? limit}) async =>
      incidents;

  @override
  Stream<List<Incident>> watchIncidentsByOrganization(String organizationId,
          {IncidentStatus? status, IncidentSeverity? severity}) =>
      Stream.value(incidents);

  @override
  Future<List<Incident>> getIncidentsBySite(
          {required String organizationId,
          required String siteId,
          IncidentStatus? status}) async =>
      incidents;

  @override
  Stream<List<Incident>> watchIncidentsBySite(
          {required String organizationId,
          required String siteId,
          IncidentStatus? status}) =>
      Stream.value(incidents);

  @override
  Future<List<Incident>> getIncidentsByReporter(
          {required String organizationId, required String reportedBy}) async =>
      incidents;

  @override
  Future<Incident> updateIncident(Incident incident) async => incident;

  @override
  Future<Incident> updateIncidentStatus(
      {required String organizationId,
      required String incidentId,
      required IncidentStatus status,
      String? resolvedBy,
      DateTime? resolvedAt}) async {
    return incidents.first;
  }
}

void main() {
  const testUser = UserProfile(
    uid: 'guard_1',
    email: 'guard@example.com',
    displayName: 'Guard Test',
    phone: '1234567890',
    role: UserRole.guard,
    organizationId: 'org_1',
  );

  const sampleSite = Site(
    siteId: 'site_100',
    organizationId: 'org_1',
    name: 'HQ Campus',
    address: '100 Silicon Way',
    latitude: 18.52,
    longitude: 73.85,
    geofenceRadius: 100.0,
  );

  Widget createTestWidget(Widget child,
      {MockIncidentRepository? repo, List<Incident>? initialIncidents}) {
    final mockRepo = repo ?? MockIncidentRepository();
    if (initialIncidents != null) {
      mockRepo.incidents = initialIncidents;
    }

    return ProviderScope(
      overrides: [
        currentUserProfileProvider
            .overrideWithValue(const AsyncValue.data(testUser)),
        activeAttendanceProvider.overrideWith((ref) => Stream.value(null)),
        sitesStreamProvider.overrideWith((ref) => Stream.value([sampleSite])),
        incidentRepositoryProvider.overrideWithValue(mockRepo),
        guardIncidentsProvider
            .overrideWith((ref) => Stream.value(initialIncidents ?? [])),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('IncidentReportScreen Widget Tests', () {
    testWidgets('renders all essential form sections and controls',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const IncidentReportScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Report Security Incident'), findsOneWidget);
      expect(find.text('Incident Classification'), findsOneWidget);
      expect(find.text('Associated Site'), findsOneWidget);
      expect(find.text('Severity Level'), findsOneWidget);
      expect(find.text('Incident Description'), findsOneWidget);
      expect(find.text('GPS Location'), findsOneWidget);
      expect(find.text('Submit Incident Report'), findsOneWidget);
    });

    testWidgets('displays error message when submitting without description',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const IncidentReportScreen()));
      await tester.pumpAndSettle();

      final submitBtn = find.text('Submit Incident Report');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a description of what happened.'),
          findsOneWidget);
    });
  });

  group('IncidentListScreen Widget Tests', () {
    testWidgets('renders empty state when no incidents exist', (tester) async {
      await tester.pumpWidget(
          createTestWidget(const IncidentListScreen(), initialIncidents: []));
      await tester.pumpAndSettle();

      expect(find.text('Incident Reports'), findsOneWidget);
      expect(find.text('No Incidents Reported'), findsOneWidget);
      expect(find.text('Report Incident'), findsOneWidget);
    });

    testWidgets('renders incident cards when incidents exist', (tester) async {
      final sample = Incident(
        incidentId: 'inc_card_1',
        organizationId: 'org_1',
        reportedBy: 'guard_1',
        siteId: 'site_100',
        type: 'Theft',
        severity: IncidentSeverity.critical,
        description: 'Server room door forced open.',
        status: IncidentStatus.open,
        createdAt: DateTime.utc(2026, 9, 10, 10, 0),
        updatedAt: DateTime.utc(2026, 9, 10, 10, 0),
      );

      await tester.pumpWidget(createTestWidget(const IncidentListScreen(),
          initialIncidents: [sample]));
      await tester.pumpAndSettle();

      expect(find.text('Theft'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.text('OPEN'), findsOneWidget);
      expect(find.text('Server room door forced open.'), findsOneWidget);
    });
  });
}

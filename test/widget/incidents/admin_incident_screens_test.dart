import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';
import 'package:cipher_x/features/identity/presentation/providers/identity_providers.dart';
import 'package:cipher_x/features/incidents/domain/entities/evidence_item.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_severity.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_status.dart';
import 'package:cipher_x/features/incidents/domain/repositories/incident_repository.dart';
import 'package:cipher_x/features/incidents/presentation/providers/admin_incident_providers.dart';
import 'package:cipher_x/features/incidents/presentation/providers/evidence_providers.dart';
import 'package:cipher_x/features/incidents/presentation/providers/incident_providers.dart';
import 'package:cipher_x/features/incidents/presentation/screens/admin_incident_detail_screen.dart';
import 'package:cipher_x/features/incidents/presentation/screens/admin_incident_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAdminIncidentRepository implements IncidentRepository {
  final List<Incident> incidents;

  MockAdminIncidentRepository({required this.incidents});

  @override
  Future<Incident> createIncident(Incident incident) async => incident;

  @override
  Future<Incident?> getIncident({
    required String organizationId,
    required String incidentId,
  }) async {
    try {
      return incidents.firstWhere((i) => i.incidentId == incidentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Incident>> getIncidentsByOrganization(
    String organizationId, {
    IncidentStatus? status,
    IncidentSeverity? severity,
    int? limit,
  }) async {
    return incidents
        .where((i) => status == null || i.status == status)
        .toList();
  }

  @override
  Stream<List<Incident>> watchIncidentsByOrganization(
    String organizationId, {
    IncidentStatus? status,
    IncidentSeverity? severity,
  }) {
    return Stream.value(
      incidents.where((i) => status == null || i.status == status).toList(),
    );
  }

  @override
  Future<List<Incident>> getIncidentsByReporter({
    required String organizationId,
    required String reportedBy,
  }) async =>
      [];

  @override
  Future<List<Incident>> getIncidentsBySite({
    required String organizationId,
    required String siteId,
    IncidentStatus? status,
  }) async =>
      [];

  @override
  Stream<List<Incident>> watchIncidentsBySite({
    required String organizationId,
    required String siteId,
    IncidentStatus? status,
  }) =>
      Stream.value([]);

  @override
  Future<Incident> updateIncident(Incident incident) async => incident;

  @override
  Future<Incident> updateIncidentStatus({
    required String organizationId,
    required String incidentId,
    required IncidentStatus status,
    String? resolvedBy,
    DateTime? resolvedAt,
    String? resolution,
  }) async {
    final idx = incidents.indexWhere((i) => i.incidentId == incidentId);
    if (idx != -1) {
      final updated = incidents[idx].copyWith(
        status: status,
        resolvedBy: resolvedBy,
        resolvedAt: resolvedAt ?? DateTime.now(),
        resolution: resolution,
      );
      incidents[idx] = updated;
      return updated;
    }
    return incidents.first;
  }
}

void main() {
  const adminUser = UserProfile(
    uid: 'admin_uid_01',
    email: 'admin@cipherx.com',
    displayName: 'Admin User',
    phone: '1234567890',
    organizationId: 'org_001',
    role: UserRole.admin,
  );

  final testIncident = Incident(
    incidentId: 'inc_test_99',
    organizationId: 'org_001',
    reportedBy: 'guard_john',
    siteId: 'Main Gate',
    type: 'Suspicious Package',
    severity: IncidentSeverity.high,
    description: 'Unattended bag spotted near south entrance.',
    status: IncidentStatus.open,
    createdAt: DateTime.utc(2026, 9, 16, 9, 30),
    updatedAt: DateTime.utc(2026, 9, 16, 9, 30),
  );

  Widget createListScreenScope({
    required List<Incident> incidents,
    UserProfile? profile = adminUser,
  }) {
    final mockRepo = MockAdminIncidentRepository(incidents: incidents);
    return ProviderScope(
      overrides: [
        currentUserProfileProvider.overrideWithValue(AsyncValue.data(profile)),
        incidentRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(
        home: AdminIncidentListScreen(),
      ),
    );
  }

  Widget createDetailScreenScope({
    required Incident incident,
    List<EvidenceItem> evidence = const [],
    UserProfile? profile = adminUser,
  }) {
    final mockRepo = MockAdminIncidentRepository(incidents: [incident]);
    return ProviderScope(
      overrides: [
        currentUserProfileProvider.overrideWithValue(AsyncValue.data(profile)),
        incidentRepositoryProvider.overrideWithValue(mockRepo),
        incidentEvidenceListProvider(incident.incidentId)
            .overrideWith((ref) => Stream.value(evidence)),
        adminIncidentDetailStreamProvider(incident.incidentId)
            .overrideWith((ref) => Stream.value(incident)),
      ],
      child: MaterialApp(
        home: AdminIncidentDetailScreen(
          incidentId: incident.incidentId,
          initialIncident: incident,
        ),
      ),
    );
  }

  group('AdminIncidentListScreen Widget Tests', () {
    testWidgets('renders empty state when no incidents exist', (tester) async {
      await tester.pumpWidget(createListScreenScope(incidents: []));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin_incidents_empty')), findsOneWidget);
      expect(find.text('No incidents reported'), findsOneWidget);
    });

    testWidgets(
        'renders list of incidents with correct operational information',
        (tester) async {
      await tester.pumpWidget(createListScreenScope(incidents: [testIncident]));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin_incidents_list')), findsOneWidget);
      expect(find.text('Suspicious Package'), findsOneWidget);
      expect(find.text('OPEN'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);
      expect(find.text('Main Gate'), findsOneWidget);
    });

    testWidgets('allows switching filter tabs', (tester) async {
      await tester.pumpWidget(createListScreenScope(incidents: [testIncident]));
      await tester.pumpAndSettle();

      // Tap on 'Investigating' filter chip
      await tester.tap(find.text('Investigating'));
      await tester.pumpAndSettle();

      // Incident was OPEN, so with filter INVESTIGATING, list is now empty
      expect(find.text('No INVESTIGATING incidents'), findsOneWidget);

      // Tap 'All' chip to reset
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('Suspicious Package'), findsOneWidget);
    });
  });

  group('AdminIncidentDetailScreen Widget Tests', () {
    testWidgets('renders complete incident operational details',
        (tester) async {
      await tester.pumpWidget(createDetailScreenScope(incident: testIncident));
      await tester.pumpAndSettle();

      expect(find.text('Incident Details'), findsOneWidget);
      expect(find.text('Suspicious Package'), findsOneWidget);
      expect(find.text('Severity: HIGH'), findsOneWidget);
      expect(find.text('Unattended bag spotted near south entrance.'),
          findsOneWidget);
      expect(find.text('Main Gate'), findsOneWidget);
      expect(find.text('guard_john'), findsOneWidget);
      expect(
          find.byKey(const Key('start_investigation_button')), findsOneWidget);
      expect(find.byKey(const Key('resolve_incident_button')), findsOneWidget);
    });

    testWidgets('opens resolution dialog and validates resolution input',
        (tester) async {
      await tester.pumpWidget(createDetailScreenScope(incident: testIncident));
      await tester.pumpAndSettle();

      // Ensure button is visible in scrollview and tap
      await tester
          .ensureVisible(find.byKey(const Key('resolve_incident_button')));
      await tester.tap(find.byKey(const Key('resolve_incident_button')));
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Resolve Incident'),
          findsNWidgets(2)); // Button text & Dialog title
      expect(find.byKey(const Key('resolution_text_field')), findsOneWidget);
      expect(find.byKey(const Key('submit_resolution_button')), findsOneWidget);

      // Submit without entering text (fails validation)
      await tester.tap(find.byKey(const Key('submit_resolution_button')));
      await tester.pumpAndSettle();

      expect(find.text('Resolution text cannot be empty or whitespace-only.'),
          findsOneWidget);

      // Enter valid resolution text
      await tester.enterText(
        find.byKey(const Key('resolution_text_field')),
        'Bomb squad verified package as harmless luggage.',
      );
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.byKey(const Key('submit_resolution_button')));
      await tester.pumpAndSettle();

      // Dialog dismisses
      expect(find.byKey(const Key('resolution_text_field')), findsNothing);
    });

    testWidgets('renders attached evidence files from PR #27 integration',
        (tester) async {
      final sampleEvidence = EvidenceItem(
        evidenceId: 'ev_001.jpg',
        incidentId: testIncident.incidentId,
        organizationId: testIncident.organizationId,
        storagePath: 'incidents/${testIncident.incidentId}/evidence/ev_001.jpg',
        fileName: 'bag_photo.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 204800,
        uploadedBy: 'guard_john',
        createdAt: DateTime.utc(2026, 9, 16, 9, 35),
      );

      await tester.pumpWidget(createDetailScreenScope(
        incident: testIncident,
        evidence: [sampleEvidence],
      ));
      await tester.pumpAndSettle();

      expect(find.text('bag_photo.jpg'), findsOneWidget);
      expect(find.text('200.0 KB'), findsOneWidget);
    });

    testWidgets(
        'resolved incident shows resolution details card and hides action buttons',
        (tester) async {
      final resolvedIncident = testIncident.copyWith(
        status: IncidentStatus.resolved,
        resolvedBy: 'admin_chief',
        resolvedAt: DateTime.utc(2026, 9, 16, 11, 0),
        resolution: 'Luggage returned to rightful passenger.',
      );

      await tester
          .pumpWidget(createDetailScreenScope(incident: resolvedIncident));
      await tester.pumpAndSettle();

      expect(find.text('Resolution Information'), findsOneWidget);
      expect(find.text('admin_chief'), findsOneWidget);
      expect(
          find.text('Luggage returned to rightful passenger.'), findsOneWidget);
      expect(find.text('This incident has been resolved and closed.'),
          findsOneWidget);
      expect(find.byKey(const Key('start_investigation_button')), findsNothing);
      expect(find.byKey(const Key('resolve_incident_button')), findsNothing);
    });
  });
}

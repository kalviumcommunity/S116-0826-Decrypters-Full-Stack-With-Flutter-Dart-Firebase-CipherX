import 'dart:async';
import 'package:cipher_x/features/incidents/domain/entities/incident.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_severity.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_status.dart';
import 'package:cipher_x/features/incidents/domain/failures/incident_failure.dart';
import 'package:cipher_x/features/incidents/domain/repositories/incident_repository.dart';
import 'package:cipher_x/features/incidents/domain/validators/incident_validator.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory fake implementation of [IncidentRepository] used to test repository contracts.
class FakeIncidentRepository implements IncidentRepository {
  final Map<String, Incident> _storage = {};
  final StreamController<List<Incident>> _streamController =
      StreamController<List<Incident>>.broadcast();

  void dispose() {
    _streamController.close();
  }

  void _notify() {
    _streamController.add(_storage.values.toList());
  }

  @override
  Future<Incident> createIncident(Incident incident) async {
    final validated = IncidentValidator.validate(incident);
    final key = '${validated.organizationId}_${validated.incidentId}';
    if (_storage.containsKey(key)) {
      throw const IncidentValidationFailure(
          'Incident with this ID already exists in organization.');
    }
    _storage[key] = validated;
    _notify();
    return validated;
  }

  @override
  Future<Incident?> getIncident({
    required String organizationId,
    required String incidentId,
  }) async {
    return _storage['${organizationId}_$incidentId'];
  }

  @override
  Future<List<Incident>> getIncidentsByOrganization(
    String organizationId, {
    IncidentStatus? status,
    IncidentSeverity? severity,
    int? limit,
  }) async {
    var list = _storage.values
        .where((inc) => inc.organizationId == organizationId)
        .toList();

    if (status != null) {
      list = list.where((inc) => inc.status == status).toList();
    }
    if (severity != null) {
      list = list.where((inc) => inc.severity == severity).toList();
    }
    if (limit != null && limit > 0 && list.length > limit) {
      list = list.sublist(0, limit);
    }
    return list;
  }

  @override
  Stream<List<Incident>> watchIncidentsByOrganization(
    String organizationId, {
    IncidentStatus? status,
    IncidentSeverity? severity,
  }) {
    return _streamController.stream.map((all) {
      var list =
          all.where((inc) => inc.organizationId == organizationId).toList();
      if (status != null) {
        list = list.where((inc) => inc.status == status).toList();
      }
      if (severity != null) {
        list = list.where((inc) => inc.severity == severity).toList();
      }
      return list;
    });
  }

  @override
  Future<List<Incident>> getIncidentsBySite({
    required String organizationId,
    required String siteId,
    IncidentStatus? status,
  }) async {
    var list = _storage.values
        .where((inc) =>
            inc.organizationId == organizationId && inc.siteId == siteId)
        .toList();

    if (status != null) {
      list = list.where((inc) => inc.status == status).toList();
    }
    return list;
  }

  @override
  Stream<List<Incident>> watchIncidentsBySite({
    required String organizationId,
    required String siteId,
    IncidentStatus? status,
  }) {
    return _streamController.stream.map((all) {
      var list = all
          .where((inc) =>
              inc.organizationId == organizationId && inc.siteId == siteId)
          .toList();
      if (status != null) {
        list = list.where((inc) => inc.status == status).toList();
      }
      return list;
    });
  }

  @override
  Future<List<Incident>> getIncidentsByReporter({
    required String organizationId,
    required String reportedBy,
  }) async {
    return _storage.values
        .where((inc) =>
            inc.organizationId == organizationId &&
            inc.reportedBy == reportedBy)
        .toList();
  }

  @override
  Future<Incident> updateIncident(Incident incident) async {
    final validated = IncidentValidator.validate(incident);
    final key = '${validated.organizationId}_${validated.incidentId}';
    if (!_storage.containsKey(key)) {
      throw const IncidentNotFoundFailure(
          'Cannot update non-existent incident.');
    }
    _storage[key] = validated;
    _notify();
    return validated;
  }

  @override
  Future<Incident> updateIncidentStatus({
    required String organizationId,
    required String incidentId,
    required IncidentStatus status,
    String? resolvedBy,
    DateTime? resolvedAt,
  }) async {
    final existing = await getIncident(
        organizationId: organizationId, incidentId: incidentId);
    if (existing == null) {
      throw const IncidentNotFoundFailure();
    }

    if (status == IncidentStatus.investigating) {
      final updated = existing.investigate();
      return updateIncident(updated);
    } else if (status == IncidentStatus.resolved) {
      if (resolvedBy == null || resolvedBy.trim().isEmpty) {
        throw const MissingResolutionMetadataFailure(
            'Resolving an incident requires non-empty resolvedBy identity.');
      }
      final updated = existing.resolve(
        resolvedBy: resolvedBy,
        resolvedAt: resolvedAt,
      );
      return updateIncident(updated);
    } else {
      // Re-evaluating or staying open
      IncidentValidator.validateStatusTransition(
          from: existing.status, to: status);
      final updated =
          existing.copyWith(status: status, updatedAt: DateTime.now());
      return updateIncident(updated);
    }
  }
}

void main() {
  group('IncidentRepository Contract Tests', () {
    late FakeIncidentRepository repository;
    final now = DateTime.utc(2026, 9, 10, 10, 0);

    setUp(() {
      repository = FakeIncidentRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    Incident createTestIncident({
      String id = 'inc_1',
      String org = 'org_1',
      String reporter = 'guard_1',
      String site = 'site_1',
      IncidentSeverity severity = IncidentSeverity.medium,
      IncidentStatus status = IncidentStatus.open,
    }) {
      return Incident(
        incidentId: id,
        organizationId: org,
        reportedBy: reporter,
        siteId: site,
        type: 'General Issue',
        severity: severity,
        description: 'Test incident description',
        status: status,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('createIncident persists incident and getIncident retrieves it',
        () async {
      final incident = createTestIncident();
      final created = await repository.createIncident(incident);
      expect(created, equals(incident));

      final retrieved = await repository.getIncident(
        organizationId: 'org_1',
        incidentId: 'inc_1',
      );
      expect(retrieved, isNotNull);
      expect(retrieved!.incidentId, equals('inc_1'));
    });

    test('getIncident enforces tenant boundary', () async {
      await repository
          .createIncident(createTestIncident(id: 'inc_1', org: 'org_1'));

      final wrongOrg = await repository.getIncident(
        organizationId: 'org_2',
        incidentId: 'inc_1',
      );
      expect(wrongOrg, isNull);
    });

    test(
        'getIncidentsByOrganization filters by organization, status, and severity',
        () async {
      await repository.createIncident(createTestIncident(
          id: 'inc_1',
          org: 'org_1',
          severity: IncidentSeverity.low,
          status: IncidentStatus.open));
      await repository.createIncident(createTestIncident(
          id: 'inc_2',
          org: 'org_1',
          severity: IncidentSeverity.critical,
          status: IncidentStatus.open));
      await repository.createIncident(createTestIncident(
          id: 'inc_3',
          org: 'org_1',
          severity: IncidentSeverity.critical,
          status: IncidentStatus.investigating));
      await repository.createIncident(createTestIncident(
          id: 'inc_4',
          org: 'org_2',
          severity: IncidentSeverity.critical,
          status: IncidentStatus.open));

      final allOrg1 = await repository.getIncidentsByOrganization('org_1');
      expect(allOrg1, hasLength(3));

      final openCritical = await repository.getIncidentsByOrganization(
        'org_1',
        status: IncidentStatus.open,
        severity: IncidentSeverity.critical,
      );
      expect(openCritical, hasLength(1));
      expect(openCritical.first.incidentId, equals('inc_2'));
    });

    test('getIncidentsBySite filters by site and organization', () async {
      await repository.createIncident(
          createTestIncident(id: 'inc_1', org: 'org_1', site: 'site_alpha'));
      await repository.createIncident(
          createTestIncident(id: 'inc_2', org: 'org_1', site: 'site_beta'));

      final alphaList = await repository.getIncidentsBySite(
        organizationId: 'org_1',
        siteId: 'site_alpha',
      );
      expect(alphaList, hasLength(1));
      expect(alphaList.first.incidentId, equals('inc_1'));
    });

    test('getIncidentsByReporter filters by reporter user', () async {
      await repository.createIncident(createTestIncident(
          id: 'inc_1', org: 'org_1', reporter: 'guard_alice'));
      await repository.createIncident(
          createTestIncident(id: 'inc_2', org: 'org_1', reporter: 'guard_bob'));

      final aliceList = await repository.getIncidentsByReporter(
        organizationId: 'org_1',
        reportedBy: 'guard_alice',
      );
      expect(aliceList, hasLength(1));
      expect(aliceList.first.incidentId, equals('inc_1'));
    });

    test(
        'updateIncidentStatus transitions to investigating and resolved cleanly',
        () async {
      await repository
          .createIncident(createTestIncident(id: 'inc_1', org: 'org_1'));

      final investigating = await repository.updateIncidentStatus(
        organizationId: 'org_1',
        incidentId: 'inc_1',
        status: IncidentStatus.investigating,
      );
      expect(investigating.status, equals(IncidentStatus.investigating));

      final resolved = await repository.updateIncidentStatus(
        organizationId: 'org_1',
        incidentId: 'inc_1',
        status: IncidentStatus.resolved,
        resolvedBy: 'supervisor_charlie',
      );
      expect(resolved.status, equals(IncidentStatus.resolved));
      expect(resolved.resolvedBy, equals('supervisor_charlie'));
      expect(resolved.resolvedAt, isNotNull);
    });

    test('updateIncidentStatus rejects invalid resolution without resolvedBy',
        () async {
      await repository
          .createIncident(createTestIncident(id: 'inc_1', org: 'org_1'));

      expect(
        () => repository.updateIncidentStatus(
          organizationId: 'org_1',
          incidentId: 'inc_1',
          status: IncidentStatus.resolved,
          resolvedBy: null,
        ),
        throwsA(isA<MissingResolutionMetadataFailure>()),
      );
    });
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/guards/data/datasources/firebase_guard_data_source.dart';
import 'package:cipher_x/features/guards/domain/entities/guard.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseGuardDataSource dataSource;

  const tOrgId = 'org-123';
  const tGuardId = 'guard-456';
  final tNow = DateTime(2026, 8, 25, 12, 0, 0);

  final tGuard = Guard(
    guardId: tGuardId,
    organizationId: tOrgId,
    name: 'Officer John Smith',
    employeeId: 'EMP-9001',
    phone: '+1 555-0199',
    email: 'john.smith@cipherx.com',
    photoUrl: 'https://example.com/photo.jpg',
    status: GuardStatus.active,
    createdAt: tNow,
    updatedAt: tNow,
  );

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FirebaseGuardDataSource(firestore: fakeFirestore);
  });

  group('FirebaseGuardDataSource Unit & Integration Tests', () {
    test('createGuard writes document with canonical Timestamps', () async {
      final result = await dataSource.createGuard(tGuard);

      expect(result.guardId, equals(tGuardId));
      expect(result.name, equals('Officer John Smith'));
      expect(result.status, equals(GuardStatus.active));
      expect(result.createdAt, isNotNull);
      expect(result.updatedAt, isNotNull);

      final doc = await fakeFirestore
          .collection('organizations')
          .doc(tOrgId)
          .collection('guards')
          .doc(tGuardId)
          .get();

      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['name'], equals('Officer John Smith'));
      expect(data['status'], equals('active'));
      expect(data['isActive'], isTrue);
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['updatedAt'], isA<Timestamp>());
    });

    test('createGuard auto-generates ID when guardId is empty', () async {
      final newGuard = tGuard.copyWith(guardId: '');

      final result = await dataSource.createGuard(newGuard);

      expect(result.guardId, isNotEmpty);
      expect(result.name, equals(tGuard.name));
    });

    test('getGuard retrieves guard and deserializes Timestamps', () async {
      await dataSource.createGuard(tGuard);

      final result = await dataSource.getGuard(
        organizationId: tOrgId,
        guardId: tGuardId,
      );

      expect(result, isNotNull);
      expect(result!.guardId, equals(tGuardId));
      expect(result.organizationId, equals(tOrgId));
      expect(result.createdAt, equals(tNow));
      expect(result.updatedAt, equals(tNow));
    });

    test('getGuard returns null when document does not exist', () async {
      final result = await dataSource.getGuard(
        organizationId: tOrgId,
        guardId: 'missing-guard',
      );

      expect(result, isNull);
    });

    test('getGuards filters out soft-deleted inactive guards by default',
        () async {
      final activeGuard = tGuard.copyWith(guardId: 'active-001');
      final inactiveGuard = tGuard.copyWith(
        guardId: 'inactive-002',
        status: GuardStatus.inactive,
      );

      await dataSource.createGuard(activeGuard);
      await dataSource.createGuard(inactiveGuard);

      final activeGuards = await dataSource.getGuards(tOrgId);

      expect(activeGuards, hasLength(1));
      expect(activeGuards.first.guardId, equals('active-001'));
      expect(activeGuards.first.status, equals(GuardStatus.active));
    });

    test('getGuards returns all guards when includeInactive is true', () async {
      final activeGuard = tGuard.copyWith(guardId: 'active-001');
      final inactiveGuard = tGuard.copyWith(
        guardId: 'inactive-002',
        status: GuardStatus.inactive,
      );

      await dataSource.createGuard(activeGuard);
      await dataSource.createGuard(inactiveGuard);

      final allGuards =
          await dataSource.getGuards(tOrgId, includeInactive: true);

      expect(allGuards, hasLength(2));
      final ids = allGuards.map((g) => g.guardId).toList();
      expect(ids, containsAll(['active-001', 'inactive-002']));
    });

    test('watchGuards emits filtered list by default', () async {
      final activeGuard = tGuard.copyWith(guardId: 'active-001');
      final inactiveGuard = tGuard.copyWith(
        guardId: 'inactive-002',
        status: GuardStatus.inactive,
      );

      await dataSource.createGuard(activeGuard);
      await dataSource.createGuard(inactiveGuard);

      final stream = dataSource.watchGuards(tOrgId);

      expect(
        stream,
        emits(predicate<List<Guard>>((list) {
          return list.length == 1 && list.first.guardId == 'active-001';
        })),
      );
    });

    test('updateGuard modifies fields and updates timestamp', () async {
      await dataSource.createGuard(tGuard);

      final updatedGuard = tGuard.copyWith(name: 'Senior Officer John Smith');

      final result = await dataSource.updateGuard(updatedGuard);

      expect(result.name, equals('Senior Officer John Smith'));

      final doc = await fakeFirestore
          .collection('organizations')
          .doc(tOrgId)
          .collection('guards')
          .doc(tGuardId)
          .get();

      expect(doc.data()!['name'], equals('Senior Officer John Smith'));
      expect(doc.data()!['updatedAt'], isA<Timestamp>());
    });

    test('updateGuard throws not-found FirebaseException when missing',
        () async {
      final missingGuard = tGuard.copyWith(guardId: 'missing-guard');

      expect(
        () => dataSource.updateGuard(missingGuard),
        throwsA(
          isA<FirebaseException>().having((e) => e.code, 'code', 'not-found'),
        ),
      );
    });

    test('updateGuardStatus updates status and isActive flag', () async {
      await dataSource.createGuard(tGuard);

      final result = await dataSource.updateGuardStatus(
        organizationId: tOrgId,
        guardId: tGuardId,
        status: GuardStatus.inactive,
      );

      expect(result.status, equals(GuardStatus.inactive));

      final doc = await fakeFirestore
          .collection('organizations')
          .doc(tOrgId)
          .collection('guards')
          .doc(tGuardId)
          .get();

      expect(doc.data()!['status'], equals('inactive'));
      expect(doc.data()!['isActive'], isFalse);
    });

    test('updateGuardStatus throws not-found for missing document', () async {
      expect(
        () => dataSource.updateGuardStatus(
          organizationId: tOrgId,
          guardId: 'missing-guard',
          status: GuardStatus.inactive,
        ),
        throwsA(
          isA<FirebaseException>().having((e) => e.code, 'code', 'not-found'),
        ),
      );
    });

    test('deleteGuard soft-deletes guard to inactive status', () async {
      await dataSource.createGuard(tGuard);

      await dataSource.deleteGuard(
        organizationId: tOrgId,
        guardId: tGuardId,
      );

      final doc = await fakeFirestore
          .collection('organizations')
          .doc(tOrgId)
          .collection('guards')
          .doc(tGuardId)
          .get();

      expect(doc.data()!['status'], equals('inactive'));
      expect(doc.data()!['isActive'], isFalse);

      final activeList = await dataSource.getGuards(tOrgId);
      expect(activeList, isEmpty);
    });
  });
}

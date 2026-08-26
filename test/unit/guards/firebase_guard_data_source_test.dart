import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// Note: Replace with actual package imports depending on the repo's name
import 'package:cipher_x/features/guards/data/datasources/firebase_guard_data_source.dart';
import 'package:cipher_x/features/guards/domain/entities/guard.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseGuardDataSource dataSource;
  const orgId = 'org-123';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FirebaseGuardDataSource(firestore: fakeFirestore);
  });

  group('FirebaseGuardDataSource', () {
    const testGuard = Guard(
      guardId: 'g-1',
      organizationId: orgId,
      name: 'Test Guard',
      employeeId: 'EMP-1',
      phone: '1234567890',
    );

    test('createGuard saves timestamps properly', () async {
      final created = await dataSource.createGuard(testGuard);

      expect(created.guardId, isNotEmpty);
      expect(created.createdAt, isNotNull);
      expect(created.updatedAt, isNotNull);

      final doc = await fakeFirestore
          .collection('organizations')
          .doc(orgId)
          .collection('guards')
          .doc(created.guardId)
          .get();

      final data = doc.data()!;
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['updatedAt'], isA<Timestamp>());
    });

    test('getGuards excludes inactive guards', () async {
      await dataSource.createGuard(
          testGuard.copyWith(guardId: 'g-1', status: GuardStatus.active));
      await dataSource.createGuard(
          testGuard.copyWith(guardId: 'g-2', status: GuardStatus.inactive));

      final guards = await dataSource.getGuards(orgId);

      expect(guards.length, 1);
      expect(guards.first.guardId, 'g-1');
    });

    test('updateGuardStatus throws typed exception if missing', () async {
      expect(
        () => dataSource.updateGuardStatus(
          organizationId: orgId,
          guardId: 'non-existent',
          status: GuardStatus.inactive,
        ),
        throwsA(
          isA<FirebaseException>().having((e) => e.code, 'code', 'not-found'),
        ),
      );
    });
  });
}

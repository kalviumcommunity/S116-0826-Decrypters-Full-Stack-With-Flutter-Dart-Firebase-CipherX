import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/activity/data/datasources/firebase_activity_data_source.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseActivityDataSource dataSource;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FirebaseActivityDataSource(firestore: fakeFirestore);
  });

  group('FirebaseActivityDataSource Tests', () {
    const orgId = 'org_test_123';

    Future<void> seedAuditLogs(int count) async {
      final collection = fakeFirestore
          .collection('organizations')
          .doc(orgId)
          .collection('auditLogs');

      for (var i = 1; i <= count; i++) {
        await collection.doc('log_$i').set({
          'id': 'log_$i',
          'organizationId': orgId,
          'actorId': 'usr_$i',
          'actorName': 'Actor $i',
          'actorRole': 'guard',
          'action': 'ACTION_$i',
          'entityType': 'shift',
          'entityId': 'shift_$i',
          'timestamp': Timestamp.fromDate(
            DateTime.utc(2026, 9, 1, 10, i),
          ),
        });
      }
    }

    test('getRecentAuditLogs returns bounded and ordered audit logs', () async {
      await seedAuditLogs(15);

      final logs = await dataSource.getRecentAuditLogs(
        organizationId: orgId,
        limit: 5,
      );

      expect(logs.length, equals(5));
      expect(logs.first.id, equals('log_15'));
      expect(logs[1].id, equals('log_14'));
      expect(logs.last.id, equals('log_11'));
    });

    test('watchRecentAuditLogs streams descending bounded logs', () async {
      await seedAuditLogs(8);

      final stream = dataSource.watchRecentAuditLogs(
        organizationId: orgId,
        limit: 5,
      );

      final logs = await stream.first;
      expect(logs.length, equals(5));
      expect(logs.first.id, equals('log_8'));
      expect(logs.last.id, equals('log_4'));
    });
  });
}

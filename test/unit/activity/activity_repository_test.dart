import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/activity/data/datasources/firebase_activity_data_source.dart';
import 'package:cipher_x/features/activity/data/repositories/activity_repository_impl.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseActivityDataSource dataSource;
  late ActivityRepositoryImpl repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FirebaseActivityDataSource(firestore: fakeFirestore);
    repository = ActivityRepositoryImpl(dataSource: dataSource);
  });

  group('ActivityRepositoryImpl Unit Tests', () {
    test('returns empty list and empty stream for empty organizationId',
        () async {
      final getResult =
          await repository.getRecentAuditLogs(organizationId: '   ');
      expect(getResult, isEmpty);

      final watchResult =
          await repository.watchRecentAuditLogs(organizationId: '').first;
      expect(watchResult, isEmpty);
    });

    test('fetches and streams audit logs successfully for valid organizationId',
        () async {
      const orgId = 'org_alpha';
      await fakeFirestore
          .collection('organizations')
          .doc(orgId)
          .collection('auditLogs')
          .doc('aud_1')
          .set({
        'id': 'aud_1',
        'organizationId': orgId,
        'actorId': 'usr_1',
        'actorName': 'Commander Alpha',
        'actorRole': 'admin',
        'action': 'SITE_CREATED',
        'entityType': 'site',
        'entityId': 'site_99',
        'timestamp': Timestamp.fromDate(DateTime.utc(2026, 9, 17, 8, 0)),
      });

      final list = await repository.getRecentAuditLogs(organizationId: orgId);
      expect(list.length, equals(1));
      expect(list.first.actorName, equals('Commander Alpha'));
      expect(list.first.action, equals('SITE_CREATED'));

      final streamList =
          await repository.watchRecentAuditLogs(organizationId: orgId).first;
      expect(streamList.length, equals(1));
      expect(streamList.first.id, equals('aud_1'));
    });
  });
}

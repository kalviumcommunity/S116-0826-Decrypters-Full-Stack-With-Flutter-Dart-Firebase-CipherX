import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/sites/data/datasources/firebase_site_data_source.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseSiteDataSource dataSource;

  const tOrgId = 'org-123';
  const tSiteId = 'site-456';
  final tNow = DateTime(2026, 8, 25, 14, 0, 0);

  final tSite = Site(
    siteId: tSiteId,
    organizationId: tOrgId,
    name: 'Cyber Gateway',
    address: 'Plot 12, HiTech City',
    latitude: 17.4435,
    longitude: 78.3772,
    geofenceRadius: 100.0,
    status: SiteStatus.active,
    createdAt: tNow,
    updatedAt: tNow,
  );

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FirebaseSiteDataSource(firestore: fakeFirestore);
  });

  group('FirebaseSiteDataSource Unit & Integration Tests', () {
    test('createSite writes document with Timestamps', () async {
      final result = await dataSource.createSite(tSite);

      expect(result.siteId, equals(tSiteId));
      expect(result.name, equals('Cyber Gateway'));
      expect(result.status, equals(SiteStatus.active));
      expect(result.createdAt, isNotNull);
      expect(result.updatedAt, isNotNull);

      final doc = await fakeFirestore
          .collection('organizations')
          .doc(tOrgId)
          .collection('sites')
          .doc(tSiteId)
          .get();

      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['name'], equals('Cyber Gateway'));
      expect(data['status'], equals('active'));
      expect(data['isActive'], isTrue);
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['updatedAt'], isA<Timestamp>());
    });

    test('createSite auto-generates ID when siteId empty', () async {
      final newSite = tSite.copyWith(siteId: '');

      final result = await dataSource.createSite(newSite);

      expect(result.siteId, isNotEmpty);
      expect(result.name, equals(tSite.name));
    });

    test('getSite retrieves site and deserializes Timestamps', () async {
      await dataSource.createSite(tSite);

      final result = await dataSource.getSite(
        organizationId: tOrgId,
        siteId: tSiteId,
      );

      expect(result, isNotNull);
      expect(result!.siteId, equals(tSiteId));
      expect(result.organizationId, equals(tOrgId));
      expect(result.createdAt, equals(tNow));
      expect(result.updatedAt, equals(tNow));
    });

    test('getSite returns null when site does not exist', () async {
      final result = await dataSource.getSite(
        organizationId: tOrgId,
        siteId: 'non-existent-site',
      );

      expect(result, isNull);
    });

    test('getSites filters out inactive sites by default', () async {
      final activeSite = tSite.copyWith(siteId: 'active-001');
      final inactiveSite = tSite.copyWith(
        siteId: 'inactive-002',
        status: SiteStatus.inactive,
      );

      await dataSource.createSite(activeSite);
      await dataSource.createSite(inactiveSite);

      final activeSites = await dataSource.getSites(tOrgId);

      expect(activeSites, hasLength(1));
      expect(activeSites.first.siteId, equals('active-001'));
      expect(activeSites.first.status, equals(SiteStatus.active));
    });

    test('getSites returns all sites when includeInactive is true', () async {
      final activeSite = tSite.copyWith(siteId: 'active-001');
      final inactiveSite = tSite.copyWith(
        siteId: 'inactive-002',
        status: SiteStatus.inactive,
      );

      await dataSource.createSite(activeSite);
      await dataSource.createSite(inactiveSite);

      final allSites = await dataSource.getSites(tOrgId, includeInactive: true);

      expect(allSites, hasLength(2));
      final siteIds = allSites.map((s) => s.siteId).toList();
      expect(siteIds, containsAll(['active-001', 'inactive-002']));
    });

    test('updateSite modifies fields and updates timestamp', () async {
      await dataSource.createSite(tSite);

      final updatedSite = tSite.copyWith(
        name: 'Updated Cyber Gateway HQ',
        geofenceRadius: 200.0,
      );

      final result = await dataSource.updateSite(updatedSite);

      expect(result.name, equals('Updated Cyber Gateway HQ'));
      expect(result.geofenceRadius, equals(200.0));

      final doc = await fakeFirestore
          .collection('organizations')
          .doc(tOrgId)
          .collection('sites')
          .doc(tSiteId)
          .get();

      expect(doc.data()!['name'], equals('Updated Cyber Gateway HQ'));
      expect(doc.data()!['geofenceRadius'], equals(200.0));
      expect(doc.data()!['updatedAt'], isA<Timestamp>());
    });

    test('updateSite throws not-found exception when missing', () async {
      final missingSite = tSite.copyWith(siteId: 'missing-site');

      expect(
        () => dataSource.updateSite(missingSite),
        throwsA(
          isA<FirebaseException>().having((e) => e.code, 'code', 'not-found'),
        ),
      );
    });

    test('updateSiteStatus updates status and isActive flag', () async {
      await dataSource.createSite(tSite);

      final result = await dataSource.updateSiteStatus(
        organizationId: tOrgId,
        siteId: tSiteId,
        status: SiteStatus.inactive,
      );

      expect(result.status, equals(SiteStatus.inactive));

      final doc = await fakeFirestore
          .collection('organizations')
          .doc(tOrgId)
          .collection('sites')
          .doc(tSiteId)
          .get();

      expect(doc.data()!['status'], equals('inactive'));
      expect(doc.data()!['isActive'], isFalse);
    });

    test('updateSiteStatus throws not-found for missing site', () async {
      expect(
        () => dataSource.updateSiteStatus(
          organizationId: tOrgId,
          siteId: 'missing-site',
          status: SiteStatus.inactive,
        ),
        throwsA(
          isA<FirebaseException>().having((e) => e.code, 'code', 'not-found'),
        ),
      );
    });

    test('deleteSite soft-deletes site to inactive status', () async {
      await dataSource.createSite(tSite);

      await dataSource.deleteSite(
        organizationId: tOrgId,
        siteId: tSiteId,
      );

      final doc = await fakeFirestore
          .collection('organizations')
          .doc(tOrgId)
          .collection('sites')
          .doc(tSiteId)
          .get();

      expect(doc.data()!['status'], equals('inactive'));
      expect(doc.data()!['isActive'], isFalse);

      final activeList = await dataSource.getSites(tOrgId);
      expect(activeList, isEmpty);
    });
  });
}

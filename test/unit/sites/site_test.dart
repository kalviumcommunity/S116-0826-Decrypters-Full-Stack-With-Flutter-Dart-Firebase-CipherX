import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';

void main() {
  final tNow = DateTime(2026, 8, 25, 14, 0, 0);

  final tSite = Site(
    siteId: 'test-site-001',
    organizationId: 'test-org-001',
    name: 'Cyber Gateway Tech Park',
    address: 'Plot 12, HiTech City, Hyderabad',
    latitude: 17.4435,
    longitude: 78.3772,
    geofenceRadius: 100.0,
    status: SiteStatus.active,
    createdAt: tNow,
    updatedAt: tNow,
  );

  group('Site Model Unit Tests', () {
    test('supports value equality including timestamps', () {
      final site2 = Site(
        siteId: 'test-site-001',
        organizationId: 'test-org-001',
        name: 'Cyber Gateway Tech Park',
        address: 'Plot 12, HiTech City, Hyderabad',
        latitude: 17.4435,
        longitude: 78.3772,
        geofenceRadius: 100.0,
        status: SiteStatus.active,
        createdAt: tNow,
        updatedAt: tNow,
      );

      expect(tSite, equals(site2));
      expect(tSite.hashCode, equals(site2.hashCode));

      final siteWithDifferentDate = tSite.copyWith(
        createdAt: DateTime(2025, 1, 1),
      );
      expect(tSite, isNot(equals(siteWithDifferentDate)));
    });

    test('serializes to Map correctly with Firestore Timestamp', () {
      final map = tSite.toMap();

      expect(map['siteId'], 'test-site-001');
      expect(map['organizationId'], 'test-org-001');
      expect(map['name'], 'Cyber Gateway Tech Park');
      expect(map['address'], 'Plot 12, HiTech City, Hyderabad');
      expect(map['latitude'], 17.4435);
      expect(map['longitude'], 78.3772);
      expect(map['geofenceRadius'], 100.0);
      expect(map['status'], 'active');
      expect(map['isActive'], true);
      expect(map['createdAt'], Timestamp.fromDate(tNow));
      expect(map['updatedAt'], Timestamp.fromDate(tNow));
    });

    test('deserializes from Map with Firestore Timestamp correctly', () {
      final map = {
        'siteId': 'test-site-001',
        'organizationId': 'test-org-001',
        'name': 'Cyber Gateway Tech Park',
        'address': 'Plot 12, HiTech City, Hyderabad',
        'latitude': 17.4435,
        'longitude': 78.3772,
        'geofenceRadius': 100.0,
        'status': 'active',
        'createdAt': Timestamp.fromDate(tNow),
        'updatedAt': Timestamp.fromDate(tNow),
      };

      final result = Site.fromMap(map);

      expect(result.siteId, 'test-site-001');
      expect(result.organizationId, 'test-org-001');
      expect(result.name, 'Cyber Gateway Tech Park');
      expect(result.latitude, 17.4435);
      expect(result.geofenceRadius, 100.0);
      expect(result.status, SiteStatus.active);
      expect(result.createdAt, tNow);
      expect(result.updatedAt, tNow);
    });

    test('fails closed by throwing FormatException for unknown status strings',
        () {
      expect(SiteStatus.fromMapString('active'), SiteStatus.active);
      expect(SiteStatus.fromMapString('inactive'), SiteStatus.inactive);
      expect(SiteStatus.fromMapString('ACTIVE'), SiteStatus.active);
      expect(SiteStatus.fromMapString('INACTIVE'), SiteStatus.inactive);

      expect(
        () => SiteStatus.fromMapString('decommissioned'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => SiteStatus.fromMapString('under_construction'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => SiteStatus.fromMapString('unknown'),
        throwsA(isA<FormatException>()),
      );
    });

    test('copyWith creates modified Site copy', () {
      final updated = tSite.copyWith(
        name: 'Updated Cyber Gateway',
        status: SiteStatus.inactive,
      );

      expect(updated.name, 'Updated Cyber Gateway');
      expect(updated.status, SiteStatus.inactive);
      expect(updated.siteId, tSite.siteId);
      expect(updated.organizationId, tSite.organizationId);
    });
  });
}

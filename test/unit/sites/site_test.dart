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
    test('supports value equality', () {
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
    });

    test('serializes to Map correctly', () {
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
      expect(map['createdAt'], tNow.toIso8601String());
      expect(map['updatedAt'], tNow.toIso8601String());
    });

    test('deserializes from Map correctly', () {
      final map = {
        'siteId': 'test-site-001',
        'organizationId': 'test-org-001',
        'name': 'Cyber Gateway Tech Park',
        'address': 'Plot 12, HiTech City, Hyderabad',
        'latitude': 17.4435,
        'longitude': 78.3772,
        'geofenceRadius': 100.0,
        'status': 'active',
        'createdAt': tNow.toIso8601String(),
        'updatedAt': tNow.toIso8601String(),
      };

      final result = Site.fromMap(map);

      expect(result.siteId, 'test-site-001');
      expect(result.organizationId, 'test-org-001');
      expect(result.name, 'Cyber Gateway Tech Park');
      expect(result.latitude, 17.4435);
      expect(result.geofenceRadius, 100.0);
      expect(result.status, SiteStatus.active);
      expect(result.createdAt, tNow);
    });

    test('handles status enum conversion and fallback', () {
      expect(SiteStatus.fromMapString('active'), SiteStatus.active);
      expect(SiteStatus.fromMapString('inactive'), SiteStatus.inactive);
      expect(SiteStatus.fromMapString('ACTIVE'), SiteStatus.active);
      expect(SiteStatus.fromMapString('INACTIVE'), SiteStatus.inactive);
      expect(SiteStatus.fromMapString('unknown'), SiteStatus.active);
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

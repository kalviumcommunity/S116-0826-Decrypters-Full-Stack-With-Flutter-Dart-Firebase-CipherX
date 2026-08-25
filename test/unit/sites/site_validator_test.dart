import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';
import 'package:cipher_x/features/sites/domain/failures/site_failure.dart';
import 'package:cipher_x/features/sites/domain/validators/site_validator.dart';

void main() {
  const tValidSite = Site(
    siteId: 'site_001',
    organizationId: 'org_001',
    name: '  Cyber Gateway  ',
    address: '  123 Tech Park Ave  ',
    latitude: 19.0760,
    longitude: 72.8777,
    geofenceRadius: 50.0,
    status: SiteStatus.active,
  );

  group('SiteValidator Tests', () {
    test('passes validation for valid site and normalizes strings', () {
      final normalized = SiteValidator.validate(tValidSite);

      expect(normalized.name, 'Cyber Gateway');
      expect(normalized.address, '123 Tech Park Ave');
      expect(normalized.latitude, 19.0760);
      expect(normalized.longitude, 72.8777);
      expect(normalized.geofenceRadius, 50.0);
    });

    test('throws SiteValidationFailure when organizationId is empty', () {
      final invalid = tValidSite.copyWith(organizationId: '   ');
      expect(
        () => SiteValidator.validate(invalid),
        throwsA(isA<SiteValidationFailure>().having(
          (e) => e.message,
          'message',
          contains('Organization ID cannot be empty'),
        )),
      );
    });

    test('throws SiteValidationFailure when name is empty', () {
      final invalid = tValidSite.copyWith(name: '   ');
      expect(
        () => SiteValidator.validate(invalid),
        throwsA(isA<SiteValidationFailure>().having(
          (e) => e.message,
          'message',
          contains('Site name cannot be empty'),
        )),
      );
    });

    test('throws SiteValidationFailure when address is empty', () {
      final invalid = tValidSite.copyWith(address: '   ');
      expect(
        () => SiteValidator.validate(invalid),
        throwsA(isA<SiteValidationFailure>().having(
          (e) => e.message,
          'message',
          contains('Site address cannot be empty'),
        )),
      );
    });

    group('Latitude Validation', () {
      test('accepts boundary latitude values (-90 and 90)', () {
        expect(SiteValidator.validateLatitude(-90.0), isNull);
        expect(SiteValidator.validateLatitude(90.0), isNull);
        expect(SiteValidator.validateLatitude(0.0), isNull);
      });

      test('rejects latitude outside range (-90.001 and 90.001)', () {
        expect(SiteValidator.validateLatitude(-90.001), isNotNull);
        expect(SiteValidator.validateLatitude(90.001), isNotNull);
      });

      test('rejects non-finite latitude (NaN and Infinity)', () {
        expect(SiteValidator.validateLatitude(double.nan), isNotNull);
        expect(SiteValidator.validateLatitude(double.infinity), isNotNull);
        expect(SiteValidator.validateLatitude(double.negativeInfinity), isNotNull);
      });
    });

    group('Longitude Validation', () {
      test('accepts boundary longitude values (-180 and 180)', () {
        expect(SiteValidator.validateLongitude(-180.0), isNull);
        expect(SiteValidator.validateLongitude(180.0), isNull);
        expect(SiteValidator.validateLongitude(0.0), isNull);
      });

      test('rejects longitude outside range (-180.001 and 180.001)', () {
        expect(SiteValidator.validateLongitude(-180.001), isNotNull);
        expect(SiteValidator.validateLongitude(180.001), isNotNull);
      });

      test('rejects non-finite longitude (NaN and Infinity)', () {
        expect(SiteValidator.validateLongitude(double.nan), isNotNull);
        expect(SiteValidator.validateLongitude(double.infinity), isNotNull);
        expect(SiteValidator.validateLongitude(double.negativeInfinity), isNotNull);
      });
    });

    group('Geofence Radius Validation', () {
      test('accepts positive geofence radius', () {
        expect(SiteValidator.validateGeofenceRadius(10.0), isNull);
        expect(SiteValidator.validateGeofenceRadius(100.0), isNull);
      });

      test('rejects zero and negative geofence radius', () {
        expect(SiteValidator.validateGeofenceRadius(0.0), isNotNull);
        expect(SiteValidator.validateGeofenceRadius(-50.0), isNotNull);
      });

      test('rejects non-finite geofence radius', () {
        expect(SiteValidator.validateGeofenceRadius(double.nan), isNotNull);
        expect(SiteValidator.validateGeofenceRadius(double.infinity), isNotNull);
      });
    });
  });
}

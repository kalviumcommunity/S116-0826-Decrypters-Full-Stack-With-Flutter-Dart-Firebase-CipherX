import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/qr/domain/entities/qr_validation_result.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';

void main() {
  const sampleSite = Site(
    siteId: 'site_test',
    organizationId: 'org_test',
    name: 'HQ Alpha',
    address: '1 Market St',
    latitude: 37.7,
    longitude: -122.4,
    geofenceRadius: 50.0,
  );

  group('QrValidationResult Entity Tests', () {
    test('valid constructor sets all flags and properties correctly', () {
      final res = QrValidationResult.valid(sampleSite);

      expect(res.status, equals(QrValidationStatus.valid));
      expect(res.isValid, isTrue);
      expect(res.isInvalidFormat, isFalse);
      expect(res.isInvalidType, isFalse);
      expect(res.isMissingSiteId, isFalse);
      expect(res.isUnsupportedVersion, isFalse);
      expect(res.isSiteNotFound, isFalse);
      expect(res.isInactiveSite, isFalse);
      expect(res.site, equals(sampleSite));
      expect(res.siteId, equals('site_test'));
    });

    test('invalidFormat constructor sets flags properly', () {
      const res = QrValidationResult.invalidFormat('Custom format error');

      expect(res.status, equals(QrValidationStatus.invalidFormat));
      expect(res.isInvalidFormat, isTrue);
      expect(res.isValid, isFalse);
      expect(res.message, equals('Custom format error'));
    });

    test('invalidType constructor sets flags properly', () {
      const res = QrValidationResult.invalidType('Wrong type');

      expect(res.status, equals(QrValidationStatus.invalidType));
      expect(res.isInvalidType, isTrue);
      expect(res.isValid, isFalse);
      expect(res.message, equals('Wrong type'));
    });

    test('missingSiteId constructor sets flags properly', () {
      const res = QrValidationResult.missingSiteId('Empty ID');

      expect(res.status, equals(QrValidationStatus.missingSiteId));
      expect(res.isMissingSiteId, isTrue);
      expect(res.isValid, isFalse);
      expect(res.message, equals('Empty ID'));
    });

    test('unsupportedVersion constructor sets flags properly', () {
      const res = QrValidationResult.unsupportedVersion('v2 not supported');

      expect(res.status, equals(QrValidationStatus.unsupportedVersion));
      expect(res.isUnsupportedVersion, isTrue);
      expect(res.isValid, isFalse);
      expect(res.message, equals('v2 not supported'));
    });

    test('siteNotFound constructor sets flags properly', () {
      const res = QrValidationResult.siteNotFound('site_999', 'Site missing');

      expect(res.status, equals(QrValidationStatus.siteNotFound));
      expect(res.isSiteNotFound, isTrue);
      expect(res.isValid, isFalse);
      expect(res.siteId, equals('site_999'));
      expect(res.message, equals('Site missing'));
    });

    test('inactiveSite constructor sets flags properly', () {
      const res =
          QrValidationResult.inactiveSite('site_inactive_1', 'Site closed');

      expect(res.status, equals(QrValidationStatus.inactiveSite));
      expect(res.isInactiveSite, isTrue);
      expect(res.isValid, isFalse);
      expect(res.siteId, equals('site_inactive_1'));
      expect(res.message, equals('Site closed'));
    });

    test('equality and hashCode verify correctly', () {
      final res1 = QrValidationResult.valid(sampleSite);
      final res2 = QrValidationResult.valid(sampleSite);
      const res3 = QrValidationResult.siteNotFound('site_other');

      expect(res1, equals(res2));
      expect(res1.hashCode, equals(res2.hashCode));
      expect(res1, isNot(equals(res3)));
    });

    test('toString contains status and site information', () {
      final res = QrValidationResult.valid(sampleSite);
      expect(res.toString(), contains('QrValidationStatus.valid'));
      expect(res.toString(), contains('HQ Alpha'));
    });
  });
}

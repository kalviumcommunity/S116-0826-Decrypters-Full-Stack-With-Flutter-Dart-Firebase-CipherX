import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cipher_x/features/qr/domain/entities/qr_validation_result.dart';
import 'package:cipher_x/features/qr/domain/entities/site_qr_payload.dart';
import 'package:cipher_x/features/qr/domain/services/qr_parser.dart';
import 'package:cipher_x/features/qr/domain/services/qr_validator.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';
import 'package:cipher_x/features/sites/domain/repositories/site_repository.dart';

class MockSiteRepository extends Mock implements SiteRepository {}

void main() {
  late QrParser parser;
  late QrValidator validator;
  late MockSiteRepository mockSiteRepository;

  const orgId = 'org_123';
  const sampleSite = Site(
    siteId: 'site_123',
    organizationId: orgId,
    name: 'Main Tech Park',
    address: '100 Silicon Way',
    latitude: 37.7749,
    longitude: -122.4194,
    geofenceRadius: 100.0,
  );

  setUp(() {
    parser = const QrParser();
    validator = QrValidator(parser: parser);
    mockSiteRepository = MockSiteRepository();
  });

  group('SiteQrPayload — Serialization & Deserialization', () {
    test('creates payload for site cleanly', () {
      final payload = SiteQrPayload.createForSite('site_123');

      expect(payload.type, equals('cipher_x_site'));
      expect(payload.siteId, equals('site_123'));
      expect(payload.version, equals(1));
    });

    test('serializes and deserializes to JSON correctly', () {
      final original = SiteQrPayload.createForSite('site_abc');
      final jsonStr = original.toJson();
      final restored = SiteQrPayload.fromJson(jsonStr);

      expect(restored, equals(original));
      expect(restored.siteId, equals('site_abc'));
    });
  });

  group('PR #22 Required Automated Tests — QR Verification', () {
    test(
        'TEST 1 — VALID QR: Valid JSON payload and existing site returns valid result',
        () async {
      const rawJson =
          '{"type": "cipher_x_site", "siteId": "site_123", "version": 1}';

      when(() => mockSiteRepository.getSite(
            organizationId: orgId,
            siteId: 'site_123',
          )).thenAnswer((_) async => sampleSite);

      final result = await validator.validateRawQr(
        rawQrData: rawJson,
        organizationId: orgId,
        siteRepository: mockSiteRepository,
      );

      expect(result.status, equals(QrValidationStatus.valid));
      expect(result.isValid, isTrue);
      expect(result.site, equals(sampleSite));
      expect(result.siteId, equals('site_123'));
    });

    test(
        'TEST 2 — INVALID JSON: Malformed non-JSON returns invalidFormat result',
        () async {
      const rawText = 'not-json-string';

      final result = await validator.validateRawQr(
        rawQrData: rawText,
        organizationId: orgId,
        siteRepository: mockSiteRepository,
      );

      expect(result.status, equals(QrValidationStatus.invalidFormat));
      expect(result.isInvalidFormat, isTrue);
      expect(result.isValid, isFalse);
    });

    test(
        'TEST 3 — WRONG TYPE: Unexpected payload type returns invalidType result',
        () async {
      const rawJson =
          '{"type": "random_type", "siteId": "site_123", "version": 1}';

      final result = await validator.validateRawQr(
        rawQrData: rawJson,
        organizationId: orgId,
        siteRepository: mockSiteRepository,
      );

      expect(result.status, equals(QrValidationStatus.invalidType));
      expect(result.isInvalidType, isTrue);
      expect(result.isValid, isFalse);
    });

    test(
        'TEST 4 — MISSING SITE ID: Payload missing siteId returns missingSiteId result',
        () async {
      const rawJson = '{"type": "cipher_x_site", "version": 1}';

      final result = await validator.validateRawQr(
        rawQrData: rawJson,
        organizationId: orgId,
        siteRepository: mockSiteRepository,
      );

      expect(result.status, equals(QrValidationStatus.missingSiteId));
      expect(result.isMissingSiteId, isTrue);
      expect(result.isValid, isFalse);
    });

    test(
        'TEST 5 — UNSUPPORTED VERSION: Future version number returns unsupportedVersion result',
        () async {
      const rawJson =
          '{"type": "cipher_x_site", "siteId": "site_123", "version": 999}';

      final result = await validator.validateRawQr(
        rawQrData: rawJson,
        organizationId: orgId,
        siteRepository: mockSiteRepository,
      );

      expect(result.status, equals(QrValidationStatus.unsupportedVersion));
      expect(result.isUnsupportedVersion, isTrue);
      expect(result.isValid, isFalse);
    });

    test(
        'TEST 6 — GENERATION -> PARSING COMPATIBILITY: Roundtrip from site payload to parser retains exact siteId',
        () async {
      final generatedPayload = SiteQrPayload.createForSite('site_123');
      final serializedJson = generatedPayload.toJson();

      when(() => mockSiteRepository.getSite(
            organizationId: orgId,
            siteId: 'site_123',
          )).thenAnswer((_) async => sampleSite);

      final result = await validator.validateRawQr(
        rawQrData: serializedJson,
        organizationId: orgId,
        siteRepository: mockSiteRepository,
      );

      expect(result.status, equals(QrValidationStatus.valid));
      expect(result.siteId, equals('site_123'));
      expect(result.site?.name, equals('Main Tech Park'));
    });

    test(
        'TEST 7 — SITE NOT FOUND: Valid QR format for non-existent site returns siteNotFound result',
        () async {
      const rawJson =
          '{"type": "cipher_x_site", "siteId": "site_nonexistent", "version": 1}';

      when(() => mockSiteRepository.getSite(
            organizationId: orgId,
            siteId: 'site_nonexistent',
          )).thenAnswer((_) async => null);

      final result = await validator.validateRawQr(
        rawQrData: rawJson,
        organizationId: orgId,
        siteRepository: mockSiteRepository,
      );

      expect(result.status, equals(QrValidationStatus.siteNotFound));
      expect(result.isSiteNotFound, isTrue);
      expect(result.isValid, isFalse);
      expect(result.siteId, equals('site_nonexistent'));
    });
  });

  group('QrParser Edge Cases', () {
    test('safely handles empty, URL, and random text inputs', () {
      expect(parser.parse(''), isNull);
      expect(parser.parse('   '), isNull);
      expect(parser.parse('https://example.com/qr'), isNull);
      expect(parser.parse('[1, 2, 3]'), isNull);
    });
  });
}

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/incidents/domain/entities/evidence_file.dart';
import 'package:cipher_x/features/incidents/domain/failures/evidence_failure.dart';
import 'package:cipher_x/features/incidents/domain/validators/evidence_validator.dart';

void main() {
  group('EvidenceValidator - Incident ID Validation', () {
    test('accepts valid alphanumeric incident IDs', () {
      expect(() => EvidenceValidator.validateIncidentId('inc_12345'),
          returnsNormally);
      expect(() => EvidenceValidator.validateIncidentId('INC-2026-001'),
          returnsNormally);
    });

    test('rejects empty and whitespace incident IDs', () {
      expect(
        () => EvidenceValidator.validateIncidentId(''),
        throwsA(isA<IncidentNotFoundFailure>()),
      );
      expect(
        () => EvidenceValidator.validateIncidentId('   '),
        throwsA(isA<IncidentNotFoundFailure>()),
      );
    });

    test('rejects path traversal in incident IDs', () {
      expect(
        () => EvidenceValidator.validateIncidentId('../incident1'),
        throwsA(isA<InvalidFileFailure>()),
      );
      expect(
        () => EvidenceValidator.validateIncidentId(r'..\incident1'),
        throwsA(isA<InvalidFileFailure>()),
      );
      expect(
        () => EvidenceValidator.validateIncidentId('incident/sub'),
        throwsA(isA<InvalidFileFailure>()),
      );
    });

    test('rejects illegal characters in incident ID', () {
      expect(
        () => EvidenceValidator.validateIncidentId('inc@123!'),
        throwsA(isA<InvalidFileFailure>()),
      );
    });
  });

  group('EvidenceValidator - Filename Sanitization', () {
    test('strips directory paths and backslashes', () {
      final sanitized =
          EvidenceValidator.sanitizeFileName(r'folder\sub/photo.jpg');
      expect(sanitized, 'photo.jpg');
    });

    test('strips path traversal sequences', () {
      final sanitized = EvidenceValidator.sanitizeFileName('../../secret.png');
      expect(sanitized, 'secret.png');
    });

    test('strips dangerous control characters and punctuation', () {
      final sanitized =
          EvidenceValidator.sanitizeFileName('bad<file>:name"?.jpg');
      expect(sanitized, 'badfilename.jpg');
    });

    test('generates fallback for empty or all-stripped filenames', () {
      final sanitized = EvidenceValidator.sanitizeFileName('   ');
      expect(sanitized.startsWith('evidence_'), isTrue);
    });

    test('truncates very long filenames while preserving extension', () {
      final longName = '${'a' * 150}.png';
      final sanitized = EvidenceValidator.sanitizeFileName(longName);
      expect(sanitized.length <= 100, isTrue);
      expect(sanitized.endsWith('.png'), isTrue);
    });
  });

  group('EvidenceValidator - File Size Boundary Matrix', () {
    test('rejects 0-byte (empty) file', () {
      expect(
        () => EvidenceValidator.validateFileSize(0),
        throwsA(isA<InvalidFileFailure>()),
      );
    });

    test('rejects negative size', () {
      expect(
        () => EvidenceValidator.validateFileSize(-1),
        throwsA(isA<InvalidFileFailure>()),
      );
    });

    test('accepts 1-byte file', () {
      expect(() => EvidenceValidator.validateFileSize(1), returnsNormally);
    });

    test('accepts exactly maximum size (10 MB = 10,485,760 bytes)', () {
      expect(
        () => EvidenceValidator.validateFileSize(10 * 1024 * 1024),
        returnsNormally,
      );
    });

    test('accepts 1 byte below maximum (10,485,759 bytes)', () {
      expect(
        () => EvidenceValidator.validateFileSize((10 * 1024 * 1024) - 1),
        returnsNormally,
      );
    });

    test('rejects 1 byte above maximum (10,485,761 bytes)', () {
      expect(
        () => EvidenceValidator.validateFileSize((10 * 1024 * 1024) + 1),
        throwsA(isA<FileTooLargeFailure>()),
      );
    });

    test('rejects significantly oversized file (25 MB)', () {
      expect(
        () => EvidenceValidator.validateFileSize(25 * 1024 * 1024),
        throwsA(isA<FileTooLargeFailure>()),
      );
    });
  });

  group('EvidenceValidator - Extension Validation', () {
    test('accepts allowed extensions', () {
      for (final ext in ['jpg', 'jpeg', 'png', 'webp', 'pdf']) {
        expect(() => EvidenceValidator.validateExtension(ext), returnsNormally);
        expect(() => EvidenceValidator.validateExtension(ext.toUpperCase()),
            returnsNormally);
      }
    });

    test('rejects dangerous and unsupported extensions', () {
      for (final ext in [
        'exe',
        'sh',
        'php',
        'bat',
        'html',
        'js',
        'zip',
        'doc'
      ]) {
        expect(
          () => EvidenceValidator.validateExtension(ext),
          throwsA(isA<UnsupportedFileTypeFailure>()),
        );
      }
    });
  });

  group('EvidenceValidator - Magic Bytes & Content Inspection', () {
    final validJpegBytes = Uint8List.fromList([
      0xFF,
      0xD8,
      0xFF,
      0xE0,
      0x00,
      0x10,
      0x4A,
      0x46,
      ...List.filled(20, 0x00),
    ]);

    final validPngBytes = Uint8List.fromList([
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      ...List.filled(20, 0x00),
    ]);

    final validPdfBytes = Uint8List.fromList([
      0x25,
      0x50,
      0x44,
      0x46,
      0x2D,
      0x31,
      0x2E,
      0x35,
      ...List.filled(20, 0x00),
    ]);

    final validWebpBytes = Uint8List.fromList([
      0x52,
      0x49,
      0x46,
      0x46,
      0x00,
      0x00,
      0x00,
      0x00,
      0x57,
      0x45,
      0x42,
      0x50,
      ...List.filled(20, 0x00),
    ]);

    test('detects correct MIME types from headers', () {
      expect(EvidenceValidator.detectMimeTypeFromMagicBytes(validJpegBytes),
          'image/jpeg');
      expect(EvidenceValidator.detectMimeTypeFromMagicBytes(validPngBytes),
          'image/png');
      expect(EvidenceValidator.detectMimeTypeFromMagicBytes(validPdfBytes),
          'application/pdf');
      expect(EvidenceValidator.detectMimeTypeFromMagicBytes(validWebpBytes),
          'image/webp');
    });

    test('returns null for unknown/corrupted headers', () {
      final junkBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
      expect(EvidenceValidator.detectMimeTypeFromMagicBytes(junkBytes), isNull);
    });

    test('validates valid EvidenceFile successfully', () {
      final file = EvidenceFile(
        name: 'photo.jpg',
        bytes: validJpegBytes,
        contentType: 'image/jpeg',
      );
      expect(
          () => EvidenceValidator.validateEvidenceFile(file), returnsNormally);
    });

    test('rejects spoofed file with fake extension and disguised content', () {
      // PDF bytes renamed to .jpg and declared as image/jpeg
      final spoofedFile = EvidenceFile(
        name: 'malware.jpg',
        bytes: validPdfBytes,
        contentType: 'image/jpeg',
      );
      expect(
        () => EvidenceValidator.validateEvidenceFile(spoofedFile),
        throwsA(isA<UnsupportedFileTypeFailure>()),
      );
    });

    test('rejects extension mismatch (JPEG bytes named .png)', () {
      final mismatchedFile = EvidenceFile(
        name: 'test.png',
        bytes: validJpegBytes,
        contentType: 'image/jpeg',
      );
      expect(
        () => EvidenceValidator.validateEvidenceFile(mismatchedFile),
        throwsA(isA<UnsupportedFileTypeFailure>()),
      );
    });

    test('rejects arbitrary undeclared content types', () {
      final weirdMimeFile = EvidenceFile(
        name: 'photo.jpg',
        bytes: validJpegBytes,
        contentType: 'application/octet-stream',
      );
      expect(
        () => EvidenceValidator.validateEvidenceFile(weirdMimeFile),
        throwsA(isA<UnsupportedFileTypeFailure>()),
      );
    });
  });

  group('EvidenceValidator - Storage Path Generator', () {
    test('builds canonical incidents/{incidentId}/evidence/{fileId} path', () {
      final path = EvidenceValidator.buildStoragePath(
        incidentId: 'inc_99',
        fileId: 'ev_001.jpg',
      );
      expect(path, 'incidents/inc_99/evidence/ev_001.jpg');
    });

    test('rejects path traversal in fileId', () {
      expect(
        () => EvidenceValidator.buildStoragePath(
          incidentId: 'inc_99',
          fileId: '../ev_001.jpg',
        ),
        throwsA(isA<InvalidFileFailure>()),
      );
      expect(
        () => EvidenceValidator.buildStoragePath(
          incidentId: 'inc_99',
          fileId: 'folder/ev_001.jpg',
        ),
        throwsA(isA<InvalidFileFailure>()),
      );
    });
  });
}

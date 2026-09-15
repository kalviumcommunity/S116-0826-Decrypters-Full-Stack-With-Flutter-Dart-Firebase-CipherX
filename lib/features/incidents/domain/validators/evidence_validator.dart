import 'dart:typed_data';

import '../entities/evidence_file.dart';
import '../failures/evidence_failure.dart';

/// Pure domain validator enforcing all security, type, size, and identity constraints
/// for incident evidence upload.
class EvidenceValidator {
  /// Hard maximum file size limit: 10 MB (10,485,760 bytes).
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Allowed file extensions (case-insensitive).
  static const Set<String> allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'pdf',
  };

  /// Allowed MIME content types.
  static const Set<String> allowedContentTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf',
  };

  /// Validates an [incidentId] parameter for format and path-traversal safety.
  static void validateIncidentId(String incidentId) {
    final trimmed = incidentId.trim();
    if (trimmed.isEmpty) {
      throw const IncidentNotFoundFailure('Incident ID cannot be empty.');
    }
    if (trimmed.contains('/') ||
        trimmed.contains(r'\') ||
        trimmed.contains('..')) {
      throw const InvalidFileFailure(
        'Invalid incident ID: Path traversal sequences are strictly prohibited.',
      );
    }
    final validChars = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!validChars.hasMatch(trimmed)) {
      throw const InvalidFileFailure(
        'Invalid incident ID: Contains illegal characters.',
      );
    }
  }

  /// Sanitizes untrusted user filenames, stripping directory separators and dangerous characters.
  static String sanitizeFileName(String rawName) {
    var name = rawName.trim();
    if (name.isEmpty) {
      return 'evidence_${DateTime.now().millisecondsSinceEpoch}';
    }

    // Strip leading directory paths if any
    name = name.replaceAll(r'\', '/');
    if (name.contains('/')) {
      name = name.split('/').last;
    }

    // Strip path traversal attempts
    name = name.replaceAll('..', '');

    // Strip control characters, quotes, or null bytes
    name = name.replaceAll(RegExp(r'[\x00-\x1F\x7F<>:\"/\\|?*]'), '');

    if (name.trim().isEmpty) {
      return 'evidence_${DateTime.now().millisecondsSinceEpoch}';
    }

    // Enforce max filename length (preserve extension if possible)
    if (name.length > 100) {
      final dotIndex = name.lastIndexOf('.');
      if (dotIndex != -1 && dotIndex > name.length - 10) {
        final ext = name.substring(dotIndex);
        name = '${name.substring(0, 95 - ext.length)}$ext';
      } else {
        name = name.substring(0, 100);
      }
    }

    return name;
  }

  /// Validates raw file size against boundaries.
  static void validateFileSize(int sizeBytes) {
    if (sizeBytes <= 0) {
      throw const InvalidFileFailure(
          'Evidence file cannot be empty (0 bytes).');
    }
    if (sizeBytes > maxFileSizeBytes) {
      throw FileTooLargeFailure(
        'File size ($sizeBytes bytes) exceeds hard limit of $maxFileSizeBytes bytes (10 MB).',
      );
    }
  }

  /// Validates file extension against the allowlist.
  static void validateExtension(String extension) {
    final cleanExt = extension.trim().toLowerCase();
    if (cleanExt.isEmpty || !allowedExtensions.contains(cleanExt)) {
      throw UnsupportedFileTypeFailure(
        "File extension '.$cleanExt' is not supported. Allowed: ${allowedExtensions.join(', ')}",
      );
    }
  }

  /// Detects MIME type from magic byte header signature.
  ///
  /// Returns `null` if the header doesn't match any known allowed signature.
  static String? detectMimeTypeFromMagicBytes(Uint8List bytes) {
    if (bytes.length < 4) return null;

    // JPEG: 0xFF, 0xD8, 0xFF
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }

    // PNG: 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }

    // PDF: %PDF- (0x25, 0x50, 0x44, 0x46)
    if (bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46) {
      return 'application/pdf';
    }

    // WEBP: RIFF....WEBP (0x52, 0x49, 0x46, 0x46 .... 0x57, 0x45, 0x42, 0x50)
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }

    return null;
  }

  /// Comprehensive file verification pipeline:
  /// 1. File size bounds
  /// 2. Filename traversal & sanitation check
  /// 3. Extension allowlist
  /// 4. Magic bytes content signature
  /// 5. Content-Type and extension consistency
  static void validateEvidenceFile(EvidenceFile file) {
    // 1. Size
    validateFileSize(file.sizeBytes);

    // 2. Extension
    final ext = file.extension;
    validateExtension(ext);

    // 3. Magic bytes
    final detectedMime = detectMimeTypeFromMagicBytes(file.bytes);
    if (detectedMime == null) {
      throw const UnsupportedFileTypeFailure(
        'File content header does not match any allowed format (JPEG, PNG, WEBP, PDF). Corrupted or disguised file rejected.',
      );
    }

    // 4. Declared content type against allowlist
    final declaredMime = file.contentType.trim().toLowerCase();
    if (!allowedContentTypes.contains(declaredMime)) {
      throw UnsupportedFileTypeFailure(
        "Declared content-type '$declaredMime' is not supported.",
      );
    }

    // 5. Cross-check extension with detected MIME type
    if (detectedMime == 'image/jpeg' && ext != 'jpg' && ext != 'jpeg') {
      throw const UnsupportedFileTypeFailure(
        'File extension mismatch: JPEG image content must have .jpg or .jpeg extension.',
      );
    }
    if (detectedMime == 'image/png' && ext != 'png') {
      throw const UnsupportedFileTypeFailure(
        'File extension mismatch: PNG image content must have .png extension.',
      );
    }
    if (detectedMime == 'image/webp' && ext != 'webp') {
      throw const UnsupportedFileTypeFailure(
        'File extension mismatch: WEBP image content must have .webp extension.',
      );
    }
    if (detectedMime == 'application/pdf' && ext != 'pdf') {
      throw const UnsupportedFileTypeFailure(
        'File extension mismatch: PDF document content must have .pdf extension.',
      );
    }

    // 6. Cross-check declared MIME with detected MIME
    if (declaredMime != detectedMime) {
      throw UnsupportedFileTypeFailure(
        'MIME type mismatch: Content header is $detectedMime but declared as $declaredMime.',
      );
    }
  }

  /// Centralized storage path generator.
  ///
  /// Guarantees canonical path format: `incidents/{incidentId}/evidence/{fileId}`
  static String buildStoragePath({
    required String incidentId,
    required String fileId,
  }) {
    validateIncidentId(incidentId);

    final cleanFileId = fileId.trim();
    if (cleanFileId.isEmpty ||
        cleanFileId.contains('/') ||
        cleanFileId.contains(r'\') ||
        cleanFileId.contains('..')) {
      throw const InvalidFileFailure(
        'Invalid file ID: Cannot contain path traversal characters.',
      );
    }

    return 'incidents/$incidentId/evidence/$cleanFileId';
  }
}

import 'dart:convert';
import '../entities/site_qr_payload.dart';

/// Pure domain service responsible for parsing raw string barcode data into [SiteQrPayload].
class QrParser {
  const QrParser();

  /// Attempts to parse raw string scanned from a QR code.
  ///
  /// Returns `null` if [rawQrData] is empty, malformed, non-JSON, or not a valid map object.
  SiteQrPayload? parse(String? rawQrData) {
    if (rawQrData == null || rawQrData.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = json.decode(rawQrData.trim());
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return SiteQrPayload.fromMap(decoded);
    } catch (_) {
      // Handles FormatException, TypeError, etc. without crashing.
      return null;
    }
  }
}

import '../../../sites/domain/repositories/site_repository.dart';
import '../entities/qr_validation_result.dart';
import '../entities/site_qr_payload.dart';
import 'qr_parser.dart';

/// Pure domain validator that validates parsed QR payloads and verifies site existence.
class QrValidator {
  final QrParser parser;

  const QrValidator({
    this.parser = const QrParser(),
  });

  /// Synchronously validates the structural payload fields.
  QrValidationResult? validatePayload(SiteQrPayload? payload) {
    if (payload == null) {
      return const QrValidationResult.invalidFormat();
    }

    if (payload.type != SiteQrPayload.expectedType) {
      return const QrValidationResult.invalidType();
    }

    if (payload.siteId.trim().isEmpty) {
      return const QrValidationResult.missingSiteId();
    }

    if (payload.version != SiteQrPayload.supportedVersion) {
      return const QrValidationResult.unsupportedVersion();
    }

    return null;
  }

  /// Asynchronously parses and validates raw QR data against the repository.
  Future<QrValidationResult> validateRawQr({
    required String rawQrData,
    required String organizationId,
    required SiteRepository siteRepository,
  }) async {
    final payload = parser.parse(rawQrData);
    final payloadError = validatePayload(payload);

    if (payloadError != null) {
      return payloadError;
    }

    try {
      final site = await siteRepository.getSite(
        organizationId: organizationId,
        siteId: payload!.siteId,
      );

      if (site == null) {
        return QrValidationResult.siteNotFound(payload.siteId);
      }

      return QrValidationResult.valid(site);
    } catch (_) {
      return QrValidationResult.siteNotFound(
        payload!.siteId,
        'Unable to verify site existence in repository.',
      );
    }
  }
}

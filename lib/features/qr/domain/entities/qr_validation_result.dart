import 'package:meta/meta.dart';
import '../../../sites/domain/entities/site.dart';

enum QrValidationStatus {
  valid,
  invalidFormat,
  invalidType,
  missingSiteId,
  unsupportedVersion,
  siteNotFound,
}

@immutable
class QrValidationResult {
  final QrValidationStatus status;
  final Site? site;
  final String? siteId;
  final String message;

  const QrValidationResult({
    required this.status,
    this.site,
    this.siteId,
    required this.message,
  });

  const QrValidationResult.valid(Site validSite)
      : status = QrValidationStatus.valid,
        site = validSite,
        siteId = validSite.siteId,
        message = 'Site QR successfully verified.';

  const QrValidationResult.invalidFormat([String? msg])
      : status = QrValidationStatus.invalidFormat,
        site = null,
        siteId = null,
        message = msg ?? 'This QR code is not a valid Cipher-X site QR format.';

  const QrValidationResult.invalidType([String? msg])
      : status = QrValidationStatus.invalidType,
        site = null,
        siteId = null,
        message = msg ?? 'Invalid QR payload type.';

  const QrValidationResult.missingSiteId([String? msg])
      : status = QrValidationStatus.missingSiteId,
        site = null,
        siteId = null,
        message = msg ?? 'QR payload missing site identifier.';

  const QrValidationResult.unsupportedVersion([String? msg])
      : status = QrValidationStatus.unsupportedVersion,
        site = null,
        siteId = null,
        message = msg ?? 'Unsupported QR payload version.';

  const QrValidationResult.siteNotFound(String id, [String? msg])
      : status = QrValidationStatus.siteNotFound,
        site = null,
        siteId = id,
        message = msg ?? 'This QR refers to a site that could not be found.';

  bool get isValid => status == QrValidationStatus.valid;
  bool get isInvalidFormat => status == QrValidationStatus.invalidFormat;
  bool get isInvalidType => status == QrValidationStatus.invalidType;
  bool get isMissingSiteId => status == QrValidationStatus.missingSiteId;
  bool get isUnsupportedVersion =>
      status == QrValidationStatus.unsupportedVersion;
  bool get isSiteNotFound => status == QrValidationStatus.siteNotFound;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrValidationResult &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          site == other.site &&
          siteId == other.siteId &&
          message == other.message;

  @override
  int get hashCode =>
      status.hashCode ^ site.hashCode ^ siteId.hashCode ^ message.hashCode;

  @override
  String toString() =>
      'QrValidationResult(status: $status, siteId: $siteId, site: ${site?.name}, message: $message)';
}

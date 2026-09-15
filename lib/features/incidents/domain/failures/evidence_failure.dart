import 'package:meta/meta.dart';

@immutable
abstract class EvidenceFailure implements Exception {
  final String message;
  final String? code;

  const EvidenceFailure(this.message, {this.code});

  @override
  String toString() => '$runtimeType: $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvidenceFailure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => Object.hash(runtimeType, message, code);
}

class UnauthenticatedFailure extends EvidenceFailure {
  const UnauthenticatedFailure([super.message = 'User is not authenticated.'])
      : super(code: 'unauthenticated');
}

class UnauthorizedFailure extends EvidenceFailure {
  const UnauthorizedFailure([
    super.message =
        'User is not authorized to attach evidence to this incident.',
  ]) : super(code: 'unauthorized');
}

class IncidentNotFoundFailure extends EvidenceFailure {
  const IncidentNotFoundFailure([
    super.message = 'Target incident was not found.',
  ]) : super(code: 'incident_not_found');
}

class OrganizationMismatchFailure extends EvidenceFailure {
  const OrganizationMismatchFailure([
    super.message = 'Incident belongs to a different organization.',
  ]) : super(code: 'org_mismatch');
}

class InvalidFileFailure extends EvidenceFailure {
  const InvalidFileFailure([super.message = 'File is invalid or corrupt.'])
      : super(code: 'invalid_file');
}

class UnsupportedFileTypeFailure extends EvidenceFailure {
  const UnsupportedFileTypeFailure([
    super.message =
        'File type is not supported. Allowed: JPEG, PNG, WEBP, PDF.',
  ]) : super(code: 'unsupported_file_type');
}

class FileTooLargeFailure extends EvidenceFailure {
  const FileTooLargeFailure([
    super.message = 'File exceeds the 10 MB size limit.',
  ]) : super(code: 'file_too_large');
}

class CompressionFailure extends EvidenceFailure {
  const CompressionFailure([
    super.message = 'Failed to compress evidence image.',
  ]) : super(code: 'compression_failed');
}

class UploadFailure extends EvidenceFailure {
  const UploadFailure([
    super.message = 'Failed to upload evidence to storage.',
  ]) : super(code: 'upload_failed');
}

class UploadCancelledFailure extends EvidenceFailure {
  const UploadCancelledFailure([
    super.message = 'Evidence upload was cancelled.',
  ]) : super(code: 'upload_cancelled');
}

class PersistenceFailure extends EvidenceFailure {
  const PersistenceFailure([
    super.message = 'Failed to persist evidence record in database.',
  ]) : super(code: 'persistence_failed');
}

class NetworkFailure extends EvidenceFailure {
  const NetworkFailure([
    super.message = 'Network error during evidence operation.',
  ]) : super(code: 'network_failure');
}

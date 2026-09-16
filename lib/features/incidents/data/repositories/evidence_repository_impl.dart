import 'dart:math';
import 'dart:typed_data';

import '../../domain/entities/evidence_file.dart';
import '../../domain/entities/evidence_item.dart';
import '../../domain/failures/evidence_failure.dart';
import '../../domain/repositories/evidence_repository.dart';
import '../../domain/repositories/incident_repository.dart';
import '../../domain/services/image_compressor.dart';
import '../../domain/validators/evidence_validator.dart';
import '../datasources/firebase_evidence_data_source.dart';
import '../datasources/firebase_storage_evidence_data_source.dart';

/// Concrete implementation of [EvidenceRepository] orchestrating file validation,
/// image compression, storage upload with progress, and Firestore metadata persistence.
class EvidenceRepositoryImpl implements EvidenceRepository {
  final FirebaseStorageEvidenceDataSource _storageDataSource;
  final FirebaseEvidenceDataSource _evidenceDataSource;
  final IncidentRepository _incidentRepository;
  final ImageCompressor _imageCompressor;

  EvidenceRepositoryImpl({
    required FirebaseStorageEvidenceDataSource storageDataSource,
    required FirebaseEvidenceDataSource evidenceDataSource,
    required IncidentRepository incidentRepository,
    required ImageCompressor imageCompressor,
  })  : _storageDataSource = storageDataSource,
        _evidenceDataSource = evidenceDataSource,
        _incidentRepository = incidentRepository,
        _imageCompressor = imageCompressor;

  String _generateCollisionResistantFileId(String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure();
    final randomPart =
        List.generate(8, (_) => random.nextInt(16).toRadixString(16)).join();
    return 'ev_${timestamp}_$randomPart.$extension';
  }

  @override
  Future<EvidenceItem> uploadEvidence({
    required String organizationId,
    required String incidentId,
    required String uploadedBy,
    required EvidenceFile file,
    void Function(double progress, int bytesTransferred, int totalBytes)?
        onProgress,
  }) async {
    // 1. Authentication check
    if (uploadedBy.trim().isEmpty) {
      throw const UnauthenticatedFailure();
    }

    // 2. Incident & Organization Authorization check
    EvidenceValidator.validateIncidentId(incidentId);

    final incident = await _incidentRepository.getIncident(
      organizationId: organizationId,
      incidentId: incidentId,
    );

    if (incident == null) {
      throw const IncidentNotFoundFailure();
    }

    if (incident.organizationId != organizationId) {
      throw const OrganizationMismatchFailure();
    }

    // 3. Pre-upload file validation (type, size, magic bytes, extension)
    EvidenceValidator.validateEvidenceFile(file);

    // 4. Image compression when applicable
    Uint8List uploadBytes = file.bytes;
    var finalContentType = file.contentType;

    if (_imageCompressor.isCompressible(file.contentType)) {
      try {
        uploadBytes = await _imageCompressor.compress(
          bytes: file.bytes,
          contentType: file.contentType,
        );
      } catch (e) {
        if (e is EvidenceFailure) rethrow;
        throw CompressionFailure('Failed to compress evidence image: $e');
      }

      // Revalidate post-compression output
      if (uploadBytes.isEmpty) {
        throw const CompressionFailure('Compressed image output was 0 bytes.');
      }
      if (uploadBytes.length > EvidenceValidator.maxFileSizeBytes) {
        throw const FileTooLargeFailure(
          'Image remains above the 10 MB limit after compression.',
        );
      }
    }

    // 5. Build secure collision-resistant storage path
    final cleanExt = file.extension;
    final fileId = _generateCollisionResistantFileId(cleanExt);
    final storagePath = EvidenceValidator.buildStoragePath(
      incidentId: incidentId,
      fileId: fileId,
    );

    final sanitizedName = EvidenceValidator.sanitizeFileName(file.name);

    // 6. Upload to Firebase Storage with progress tracking
    try {
      await _storageDataSource.uploadBytes(
        storagePath: storagePath,
        bytes: uploadBytes,
        contentType: finalContentType,
        customMetadata: {
          'organizationId': organizationId,
          'incidentId': incidentId,
          'uploadedBy': uploadedBy,
          'originalFileName': sanitizedName,
        },
        onProgress: onProgress,
      );
    } catch (e) {
      if (e is EvidenceFailure) rethrow;
      throw UploadFailure('Failed to complete upload: $e');
    }

    // 7. Persist metadata record in Firestore with atomic rollback on failure
    final evidenceItem = EvidenceItem(
      evidenceId: fileId,
      incidentId: incidentId,
      organizationId: organizationId,
      storagePath: storagePath,
      fileName: sanitizedName,
      contentType: finalContentType,
      sizeBytes: uploadBytes.length,
      uploadedBy: uploadedBy,
      createdAt: DateTime.now(),
    );

    try {
      return await _evidenceDataSource.recordEvidence(evidenceItem);
    } catch (persistenceError) {
      // Partial failure rollback: clean up orphaned storage object
      await _storageDataSource.deleteFile(storagePath);

      if (persistenceError is EvidenceFailure) rethrow;
      throw PersistenceFailure(
        'Failed to record evidence metadata. Storage file rolled back: $persistenceError',
      );
    }
  }

  @override
  Future<List<EvidenceItem>> getEvidenceForIncident({
    required String organizationId,
    required String incidentId,
  }) async {
    EvidenceValidator.validateIncidentId(incidentId);
    return _evidenceDataSource.getEvidenceForIncident(
      organizationId: organizationId,
      incidentId: incidentId,
    );
  }

  @override
  Stream<List<EvidenceItem>> watchEvidenceForIncident({
    required String organizationId,
    required String incidentId,
  }) {
    EvidenceValidator.validateIncidentId(incidentId);
    return _evidenceDataSource.watchEvidenceForIncident(
      organizationId: organizationId,
      incidentId: incidentId,
    );
  }

  @override
  Future<String> getEvidenceDownloadUrl(String storagePath) async {
    return _storageDataSource.getDownloadUrl(storagePath);
  }

  @override
  Future<void> deleteEvidence({
    required String organizationId,
    required String incidentId,
    required String evidenceId,
  }) async {
    EvidenceValidator.validateIncidentId(incidentId);

    // 1. Delete firestore record
    await _evidenceDataSource.deleteEvidence(
      organizationId: organizationId,
      incidentId: incidentId,
      evidenceId: evidenceId,
    );

    // 2. Delete storage file
    final storagePath = EvidenceValidator.buildStoragePath(
      incidentId: incidentId,
      fileId: evidenceId,
    );
    await _storageDataSource.deleteFile(storagePath);
  }
}

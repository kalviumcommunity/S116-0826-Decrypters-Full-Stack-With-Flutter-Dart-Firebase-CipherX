import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/failures/evidence_failure.dart';

/// Data source encapsulating all direct interactions with Firebase Storage for incident evidence.
class FirebaseStorageEvidenceDataSource {
  final FirebaseStorage _storage;

  FirebaseStorageEvidenceDataSource({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Uploads raw file bytes to [storagePath] and emits real upload progress.
  Future<String> uploadBytes({
    required String storagePath,
    required Uint8List bytes,
    required String contentType,
    Map<String, String>? customMetadata,
    void Function(double progress, int bytesTransferred, int totalBytes)?
        onProgress,
  }) async {
    try {
      final ref = _storage.ref().child(storagePath);
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: customMetadata,
      );

      final uploadTask = ref.putData(bytes, metadata);

      StreamSubscription<TaskSnapshot>? progressSub;
      if (onProgress != null) {
        progressSub = uploadTask.snapshotEvents.listen((snapshot) {
          final total = snapshot.totalBytes;
          final transferred = snapshot.bytesTransferred;
          if (total > 0) {
            final progress = (transferred / total).clamp(0.0, 1.0);
            onProgress(progress, transferred, total);
          }
        });
      }

      final completedSnapshot = await uploadTask;
      await progressSub?.cancel();

      if (completedSnapshot.state != TaskState.success) {
        throw const UploadFailure(
            'Storage upload task did not reach success state.');
      }

      return storagePath;
    } on FirebaseException catch (e) {
      if (e.code == 'canceled') {
        throw const UploadCancelledFailure();
      }
      if (e.code == 'unauthenticated') {
        throw const UnauthenticatedFailure();
      }
      if (e.code == 'unauthorized' || e.code == 'permission-denied') {
        throw const UnauthorizedFailure(
          'Storage permission denied for evidence upload.',
        );
      }
      if (e.code == 'network-request-failed' ||
          e.code == 'retry-limit-exceeded') {
        throw const NetworkFailure(
          'Network error while uploading evidence to storage.',
        );
      }
      throw UploadFailure(
          'Firebase Storage upload error: ${e.message ?? e.code}');
    } catch (e) {
      if (e is EvidenceFailure) rethrow;
      throw UploadFailure('Unexpected upload error: $e');
    }
  }

  /// Retrieves download URL for an uploaded storage file.
  Future<String> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        throw const EvidenceNotFoundFailure();
      }
      if (e.code == 'unauthenticated') {
        throw const UnauthenticatedFailure();
      }
      if (e.code == 'unauthorized' || e.code == 'permission-denied') {
        throw const UnauthorizedFailure(
          'Storage permission denied for evidence download URL.',
        );
      }
      throw EvidenceDownloadUrlFailure(e.message ?? e.code);
    } catch (e) {
      if (e is EvidenceFailure) rethrow;
      throw EvidenceDownloadUrlFailure(
          'Unexpected error getting download URL: $e');
    }
  }

  /// Deletes an uploaded storage object (used for cleanup on partial failure).
  Future<void> deleteFile(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.delete();
    } catch (_) {
      // Safe best-effort cleanup; do not mask original failure
    }
  }
}

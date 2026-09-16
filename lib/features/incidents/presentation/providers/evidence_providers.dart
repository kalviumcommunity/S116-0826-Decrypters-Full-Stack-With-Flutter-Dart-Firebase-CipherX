import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../identity/presentation/providers/identity_providers.dart';
import '../../data/datasources/firebase_evidence_data_source.dart';
import '../../data/datasources/firebase_storage_evidence_data_source.dart';
import '../../data/repositories/evidence_repository_impl.dart';
import '../../data/services/flutter_image_compressor.dart';
import '../../domain/entities/evidence_file.dart';
import '../../domain/entities/evidence_item.dart';
import '../../domain/failures/evidence_failure.dart';
import '../../domain/repositories/evidence_repository.dart';
import '../../domain/services/image_compressor.dart';
import 'incident_providers.dart';

/// Provider for the Firebase Storage evidence data source.
final storageEvidenceDataSourceProvider =
    Provider<FirebaseStorageEvidenceDataSource>((ref) {
  return FirebaseStorageEvidenceDataSource();
});

/// Provider for the Firestore evidence metadata data source.
final firestoreEvidenceDataSourceProvider =
    Provider<FirebaseEvidenceDataSource>((ref) {
  return FirebaseEvidenceDataSource();
});

/// Provider for the image compression service.
final imageCompressorProvider = Provider<ImageCompressor>((ref) {
  return const FlutterImageCompressor();
});

/// Provider for the concrete [EvidenceRepository].
final evidenceRepositoryProvider = Provider<EvidenceRepository>((ref) {
  final storageDs = ref.watch(storageEvidenceDataSourceProvider);
  final firestoreDs = ref.watch(firestoreEvidenceDataSourceProvider);
  final incidentRepo = ref.watch(incidentRepositoryProvider);
  final compressor = ref.watch(imageCompressorProvider);

  return EvidenceRepositoryImpl(
    storageDataSource: storageDs,
    evidenceDataSource: firestoreDs,
    incidentRepository: incidentRepo,
    imageCompressor: compressor,
  );
});

/// Real-time stream of evidence items associated with [incidentId].
final incidentEvidenceListProvider =
    StreamProvider.family<List<EvidenceItem>, String>((ref, incidentId) {
  final userProfile = ref.watch(currentUserProfileProvider).asData?.value;
  if (userProfile == null || userProfile.organizationId.isEmpty) {
    return Stream.value([]);
  }

  final repository = ref.watch(evidenceRepositoryProvider);
  return repository.watchEvidenceForIncident(
    organizationId: userProfile.organizationId,
    incidentId: incidentId,
  );
});

/// Provider to fetch download URL for a storage path.
final evidenceDownloadUrlProvider =
    FutureProvider.family<String, String>((ref, storagePath) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return repository.getEvidenceDownloadUrl(storagePath);
});

/// Upload lifecycle status states.
enum EvidenceUploadStatus {
  idle,
  validating,
  compressing,
  uploading,
  persisting,
  success,
  failure,
}

/// State representation for evidence upload controller.
class EvidenceUploadState {
  final EvidenceUploadStatus status;
  final double progress;
  final int bytesTransferred;
  final int totalBytes;
  final String? errorMessage;
  final EvidenceItem? uploadedItem;

  const EvidenceUploadState({
    this.status = EvidenceUploadStatus.idle,
    this.progress = 0.0,
    this.bytesTransferred = 0,
    this.totalBytes = 0,
    this.errorMessage,
    this.uploadedItem,
  });

  bool get isUploading =>
      status == EvidenceUploadStatus.validating ||
      status == EvidenceUploadStatus.compressing ||
      status == EvidenceUploadStatus.uploading ||
      status == EvidenceUploadStatus.persisting;

  bool get isSuccess => status == EvidenceUploadStatus.success;
  bool get hasError => status == EvidenceUploadStatus.failure;

  EvidenceUploadState copyWith({
    EvidenceUploadStatus? status,
    double? progress,
    int? bytesTransferred,
    int? totalBytes,
    String? errorMessage,
    EvidenceItem? uploadedItem,
    bool clearError = false,
  }) {
    return EvidenceUploadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      uploadedItem: uploadedItem ?? this.uploadedItem,
    );
  }
}

/// Controller managing evidence upload lifecycle, duplicate protection, and progress tracking.
class EvidenceUploadController extends StateNotifier<EvidenceUploadState> {
  final Ref _ref;

  EvidenceUploadController(this._ref) : super(const EvidenceUploadState());

  /// Initiates evidence upload with duplicate-action guards and typed error handling.
  Future<bool> uploadEvidence({
    required String incidentId,
    required EvidenceFile file,
  }) async {
    // 1. Duplicate upload guard: prevent repeated triggers while in-flight
    if (state.isUploading) {
      return false;
    }

    state = state.copyWith(
      status: EvidenceUploadStatus.validating,
      progress: 0.0,
      bytesTransferred: 0,
      totalBytes: file.sizeBytes,
      clearError: true,
    );

    try {
      final userProfile = _ref.read(currentUserProfileProvider).asData?.value;
      if (userProfile == null || userProfile.uid.isEmpty) {
        throw const UnauthenticatedFailure();
      }

      final repository = _ref.read(evidenceRepositoryProvider);
      final compressor = _ref.read(imageCompressorProvider);

      if (compressor.isCompressible(file.contentType)) {
        state = state.copyWith(status: EvidenceUploadStatus.compressing);
      }

      state = state.copyWith(status: EvidenceUploadStatus.uploading);

      final result = await repository.uploadEvidence(
        organizationId: userProfile.organizationId,
        incidentId: incidentId,
        uploadedBy: userProfile.uid,
        file: file,
        onProgress: (progress, transferred, total) {
          if (mounted) {
            state = state.copyWith(
              status: EvidenceUploadStatus.uploading,
              progress: progress,
              bytesTransferred: transferred,
              totalBytes: total,
            );
          }
        },
      );

      if (!mounted) return true;
      state = state.copyWith(
        status: EvidenceUploadStatus.success,
        progress: 1.0,
        bytesTransferred: result.sizeBytes,
        totalBytes: result.sizeBytes,
        uploadedItem: result,
      );

      return true;
    } on EvidenceFailure catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        status: EvidenceUploadStatus.failure,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        status: EvidenceUploadStatus.failure,
        errorMessage: 'An unexpected error occurred during evidence upload: $e',
      );
      return false;
    }
  }

  /// Safely retries the upload with the same incident and file candidate.
  Future<bool> retry({
    required String incidentId,
    required EvidenceFile file,
  }) async {
    reset();
    return uploadEvidence(incidentId: incidentId, file: file);
  }

  /// Resets controller state to idle.
  void reset() {
    state = const EvidenceUploadState();
  }
}

/// Provider for [EvidenceUploadController].
final evidenceUploadControllerProvider = StateNotifierProvider.autoDispose<
    EvidenceUploadController, EvidenceUploadState>(
  (ref) => EvidenceUploadController(ref),
);

import '../entities/evidence_file.dart';
import '../entities/evidence_item.dart';

/// Pure domain repository contract for incident evidence operations.
abstract class EvidenceRepository {
  /// Uploads and records evidence for [incidentId] in [organizationId].
  ///
  /// Invokes [onProgress] with values from `0.0` to `1.0`.
  /// Throws concrete [EvidenceFailure] on failure.
  Future<EvidenceItem> uploadEvidence({
    required String organizationId,
    required String incidentId,
    required String uploadedBy,
    required EvidenceFile file,
    void Function(double progress, int bytesTransferred, int totalBytes)?
        onProgress,
  });

  /// Retrieves list of evidence items attached to [incidentId].
  Future<List<EvidenceItem>> getEvidenceForIncident({
    required String organizationId,
    required String incidentId,
  });

  /// Real-time stream of evidence items attached to [incidentId].
  Stream<List<EvidenceItem>> watchEvidenceForIncident({
    required String organizationId,
    required String incidentId,
  });

  /// Deletes an evidence item and its associated storage object.
  Future<void> deleteEvidence({
    required String organizationId,
    required String incidentId,
    required String evidenceId,
  });
}

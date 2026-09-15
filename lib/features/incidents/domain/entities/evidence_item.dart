import 'package:meta/meta.dart';

/// Pure domain entity representing an uploaded, verified incident evidence item.
@immutable
class EvidenceItem {
  final String evidenceId;
  final String incidentId;
  final String organizationId;
  final String storagePath;
  final String fileName;
  final String contentType;
  final int sizeBytes;
  final String uploadedBy;
  final DateTime createdAt;

  const EvidenceItem({
    required this.evidenceId,
    required this.incidentId,
    required this.organizationId,
    required this.storagePath,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    required this.uploadedBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'evidenceId': evidenceId,
      'incidentId': incidentId,
      'organizationId': organizationId,
      'storagePath': storagePath,
      'fileName': fileName,
      'contentType': contentType,
      'sizeBytes': sizeBytes,
      'uploadedBy': uploadedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EvidenceItem.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedCreatedAt;
    final rawCreated = map['createdAt'];
    if (rawCreated is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else if (rawCreated != null &&
        rawCreated.toString().contains('Timestamp')) {
      try {
        parsedCreatedAt = (rawCreated as dynamic).toDate();
      } catch (_) {
        parsedCreatedAt = DateTime.now();
      }
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return EvidenceItem(
      evidenceId: id.isNotEmpty ? id : (map['evidenceId'] as String? ?? ''),
      incidentId: map['incidentId'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      storagePath: map['storagePath'] as String? ?? '',
      fileName: map['fileName'] as String? ?? '',
      contentType: map['contentType'] as String? ?? '',
      sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
      uploadedBy: map['uploadedBy'] as String? ?? '',
      createdAt: parsedCreatedAt,
    );
  }

  EvidenceItem copyWith({
    String? evidenceId,
    String? incidentId,
    String? organizationId,
    String? storagePath,
    String? fileName,
    String? contentType,
    int? sizeBytes,
    String? uploadedBy,
    DateTime? createdAt,
  }) {
    return EvidenceItem(
      evidenceId: evidenceId ?? this.evidenceId,
      incidentId: incidentId ?? this.incidentId,
      organizationId: organizationId ?? this.organizationId,
      storagePath: storagePath ?? this.storagePath,
      fileName: fileName ?? this.fileName,
      contentType: contentType ?? this.contentType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvidenceItem &&
          runtimeType == other.runtimeType &&
          evidenceId == other.evidenceId &&
          incidentId == other.incidentId &&
          organizationId == other.organizationId &&
          storagePath == other.storagePath &&
          sizeBytes == other.sizeBytes;

  @override
  int get hashCode => Object.hash(
      evidenceId, incidentId, organizationId, storagePath, sizeBytes);
}

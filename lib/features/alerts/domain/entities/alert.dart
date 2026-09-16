import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'alert_status.dart';
import 'alert_type.dart';
import '../failures/alert_failure.dart';

/// Pure domain entity representing an operational security alert in Cipher-X.
///
/// Enforces strict tenant isolation ([organizationId]) and deterministic deduplication.
@immutable
class Alert {
  final String alertId;
  final String organizationId;
  final AlertType type;
  final String sourceEntityId;
  final String sourceEntityType; // 'shift', 'site', 'incident'
  final DateTime createdAt;
  final AlertStatus status;
  final Map<String, dynamic> metadata;

  const Alert({
    required this.alertId,
    required this.organizationId,
    required this.type,
    required this.sourceEntityId,
    required this.sourceEntityType,
    required this.createdAt,
    this.status = AlertStatus.active,
    this.metadata = const {},
  });

  Alert copyWith({
    String? alertId,
    String? organizationId,
    AlertType? type,
    String? sourceEntityId,
    String? sourceEntityType,
    DateTime? createdAt,
    AlertStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return Alert(
      alertId: alertId ?? this.alertId,
      organizationId: organizationId ?? this.organizationId,
      type: type ?? this.type,
      sourceEntityId: sourceEntityId ?? this.sourceEntityId,
      sourceEntityType: sourceEntityType ?? this.sourceEntityType,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'alertId': alertId,
      'organizationId': organizationId,
      'type': type.toMapString(),
      'sourceEntityId': sourceEntityId,
      'sourceEntityType': sourceEntityType,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.toMapString(),
      'metadata': metadata,
    };
  }

  factory Alert.fromMap(Map<String, dynamic> map, [String? fallbackId]) {
    final alertId = (map['alertId'] as String?)?.trim() ?? fallbackId?.trim() ?? '';
    final organizationId = (map['organizationId'] as String?)?.trim() ?? '';
    final rawType = map['type'] as String?;
    final sourceEntityId = (map['sourceEntityId'] as String?)?.trim() ?? '';
    final sourceEntityType = (map['sourceEntityType'] as String?)?.trim() ?? '';
    final rawStatus = map['status'] as String? ?? 'active';

    if (alertId.isEmpty) {
      throw const InvalidAlertDataFailure('Alert ID cannot be empty.');
    }
    if (organizationId.isEmpty) {
      throw const InvalidAlertDataFailure('Organization ID cannot be empty.');
    }
    if (rawType == null || rawType.isEmpty) {
      throw const InvalidAlertDataFailure('Alert type cannot be empty.');
    }
    if (sourceEntityId.isEmpty) {
      throw const InvalidAlertDataFailure('Source entity ID cannot be empty.');
    }

    DateTime createdAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    final rawMetadata = map['metadata'];
    final metadata = rawMetadata is Map
        ? Map<String, dynamic>.from(rawMetadata)
        : <String, dynamic>{};

    return Alert(
      alertId: alertId,
      organizationId: organizationId,
      type: AlertType.fromMapString(rawType),
      sourceEntityId: sourceEntityId,
      sourceEntityType: sourceEntityType.isNotEmpty ? sourceEntityType : 'unknown',
      createdAt: createdAt,
      status: AlertStatus.fromMapString(rawStatus),
      metadata: metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Alert &&
        other.alertId == alertId &&
        other.organizationId == organizationId &&
        other.type == type &&
        other.sourceEntityId == sourceEntityId &&
        other.sourceEntityType == sourceEntityType &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(
        alertId,
        organizationId,
        type,
        sourceEntityId,
        sourceEntityType,
        status,
      );
}

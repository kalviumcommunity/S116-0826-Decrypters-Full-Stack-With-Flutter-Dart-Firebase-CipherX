import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';

/// Pure domain entity representing an operational audit log entry in Cipher-X.
///
/// Enforces tenant isolation ([organizationId]) and records operational actions
/// performed across the platform by authorized actors.
@immutable
class AuditLog {
  final String id;
  final String organizationId;
  final String actorId;
  final String actorName;
  final String actorRole;
  final String action;
  final String entityType;
  final String entityId;
  final DateTime? timestamp;
  final Map<String, dynamic> metadata;

  const AuditLog({
    required this.id,
    required this.organizationId,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.timestamp,
    this.metadata = const {},
  });

  AuditLog copyWith({
    String? id,
    String? organizationId,
    String? actorId,
    String? actorName,
    String? actorRole,
    String? action,
    String? entityType,
    String? entityId,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return AuditLog(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      actorRole: actorRole ?? this.actorRole,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizationId': organizationId,
      'actorId': actorId,
      'actorName': actorName,
      'actorRole': actorRole,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      if (timestamp != null) 'timestamp': Timestamp.fromDate(timestamp!),
      'metadata': metadata,
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map, [String? fallbackId]) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return null;
    }

    final rawMeta = map['metadata'];
    final metaMap =
        rawMeta is Map<String, dynamic> ? rawMeta : <String, dynamic>{};

    return AuditLog(
      id: (map['id'] as String?)?.trim() ?? fallbackId?.trim() ?? '',
      organizationId: (map['organizationId'] as String?)?.trim() ?? '',
      actorId: (map['actorId'] as String?)?.trim() ?? '',
      actorName: (map['actorName'] as String?)?.trim() ?? 'System User',
      actorRole: (map['actorRole'] as String?)?.trim() ?? 'guard',
      action: (map['action'] as String?)?.trim() ?? 'UNKNOWN_ACTION',
      entityType: (map['entityType'] as String?)?.trim() ?? 'system',
      entityId: (map['entityId'] as String?)?.trim() ?? '',
      timestamp: parseDate(map['timestamp']),
      metadata: metaMap,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuditLog &&
        other.id == id &&
        other.organizationId == organizationId &&
        other.actorId == actorId &&
        other.actorName == actorName &&
        other.actorRole == actorRole &&
        other.action == action &&
        other.entityType == entityType &&
        other.entityId == entityId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      organizationId,
      actorId,
      actorName,
      actorRole,
      action,
      entityType,
      entityId,
    );
  }
}

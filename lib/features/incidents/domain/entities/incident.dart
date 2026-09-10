import 'package:meta/meta.dart';

enum IncidentType {
  theft,
  vandalism,
  trespassing,
  equipmentFailure,
  medical,
  unsecuredAccess,
  other;

  String get displayName {
    switch (this) {
      case IncidentType.theft:
        return 'Theft / Stolen Property';
      case IncidentType.vandalism:
        return 'Vandalism / Property Damage';
      case IncidentType.trespassing:
        return 'Trespassing / Intruder';
      case IncidentType.equipmentFailure:
        return 'Equipment Failure';
      case IncidentType.medical:
        return 'Medical Emergency';
      case IncidentType.unsecuredAccess:
        return 'Unsecured Door / Access Point';
      case IncidentType.other:
        return 'Other Anomaly';
    }
  }

  String toMapString() => name;

  static IncidentType fromMapString(String value) {
    switch (value.toLowerCase()) {
      case 'theft':
        return IncidentType.theft;
      case 'vandalism':
        return IncidentType.vandalism;
      case 'trespassing':
        return IncidentType.trespassing;
      case 'equipmentfailure':
      case 'equipment_failure':
        return IncidentType.equipmentFailure;
      case 'medical':
        return IncidentType.medical;
      case 'unsecuredaccess':
      case 'unsecured_access':
        return IncidentType.unsecuredAccess;
      case 'other':
      default:
        return IncidentType.other;
    }
  }
}

enum IncidentSeverity {
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case IncidentSeverity.low:
        return 'Low';
      case IncidentSeverity.medium:
        return 'Medium';
      case IncidentSeverity.high:
        return 'High';
      case IncidentSeverity.critical:
        return 'Critical';
    }
  }

  String toMapString() => name;

  static IncidentSeverity fromMapString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return IncidentSeverity.low;
      case 'medium':
        return IncidentSeverity.medium;
      case 'high':
        return IncidentSeverity.high;
      case 'critical':
        return IncidentSeverity.critical;
      default:
        return IncidentSeverity.low;
    }
  }
}

enum IncidentStatus {
  open,
  underReview,
  resolved;

  String get displayName {
    switch (this) {
      case IncidentStatus.open:
        return 'Open';
      case IncidentStatus.underReview:
        return 'Under Review';
      case IncidentStatus.resolved:
        return 'Resolved';
    }
  }

  String toMapString() {
    switch (this) {
      case IncidentStatus.open:
        return 'open';
      case IncidentStatus.underReview:
        return 'under_review';
      case IncidentStatus.resolved:
        return 'resolved';
    }
  }

  static IncidentStatus fromMapString(String value) {
    switch (value.toLowerCase()) {
      case 'open':
        return IncidentStatus.open;
      case 'underreview':
      case 'under_review':
        return IncidentStatus.underReview;
      case 'resolved':
        return IncidentStatus.resolved;
      default:
        return IncidentStatus.open;
    }
  }
}

@immutable
class Incident {
  final String incidentId;
  final String organizationId;
  final String siteId;
  final String guardId;
  final IncidentType type;
  final IncidentSeverity severity;
  final String description;
  final IncidentStatus status;
  final double? latitude;
  final double? longitude;
  final List<String> evidenceUrls;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Incident({
    required this.incidentId,
    required this.organizationId,
    required this.siteId,
    required this.guardId,
    required this.type,
    required this.severity,
    required this.description,
    this.status = IncidentStatus.open,
    this.latitude,
    this.longitude,
    this.evidenceUrls = const [],
    this.createdAt,
    this.updatedAt,
  });

  Incident copyWith({
    String? incidentId,
    String? organizationId,
    String? siteId,
    String? guardId,
    IncidentType? type,
    IncidentSeverity? severity,
    String? description,
    IncidentStatus? status,
    double? latitude,
    double? longitude,
    List<String>? evidenceUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Incident(
      incidentId: incidentId ?? this.incidentId,
      organizationId: organizationId ?? this.organizationId,
      siteId: siteId ?? this.siteId,
      guardId: guardId ?? this.guardId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'incidentId': incidentId,
      'organizationId': organizationId,
      'siteId': siteId,
      'guardId': guardId,
      'type': type.toMapString(),
      'severity': severity.toMapString(),
      'description': description,
      'status': status.toMapString(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'evidenceUrls': evidenceUrls,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory Incident.fromMap(Map<String, dynamic> map, [String? fallbackId]) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      try {
        return (val as dynamic).toDate();
      } catch (_) {
        return DateTime.now();
      }
    }

    final rawEvidence = map['evidenceUrls'];
    final evidenceList = rawEvidence is List
        ? rawEvidence.map((e) => e.toString()).toList()
        : <String>[];

    return Incident(
      incidentId: (map['incidentId'] as String?) ?? fallbackId ?? '',
      organizationId: (map['organizationId'] as String?) ?? '',
      siteId: (map['siteId'] as String?) ?? '',
      guardId: (map['guardId'] as String?) ?? '',
      type: IncidentType.fromMapString((map['type'] as String?) ?? 'other'),
      severity:
          IncidentSeverity.fromMapString((map['severity'] as String?) ?? 'low'),
      description: (map['description'] as String?) ?? '',
      status:
          IncidentStatus.fromMapString((map['status'] as String?) ?? 'open'),
      latitude:
          map['latitude'] is num ? (map['latitude'] as num).toDouble() : null,
      longitude:
          map['longitude'] is num ? (map['longitude'] as num).toDouble() : null,
      evidenceUrls: evidenceList,
      createdAt: map['createdAt'] != null ? parseDate(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Incident &&
        other.incidentId == incidentId &&
        other.organizationId == organizationId &&
        other.siteId == siteId &&
        other.guardId == guardId &&
        other.type == type &&
        other.severity == severity &&
        other.description == description &&
        other.status == status &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode {
    return Object.hash(
      incidentId,
      organizationId,
      siteId,
      guardId,
      type,
      severity,
      description,
      status,
      latitude,
      longitude,
    );
  }
}

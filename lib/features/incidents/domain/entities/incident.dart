import 'package:meta/meta.dart';
import '../failures/incident_failure.dart';
import '../validators/incident_validator.dart';
import 'incident_severity.dart';
import 'incident_status.dart';

/// Pure domain entity representing a security incident in Cipher-X.
///
/// Contains all 14 conceptual fields defined by the Master Development Plan.
/// Preserves strict tenant isolation through [organizationId] and immutable audit identity.
@immutable
class Incident {
  final String incidentId;
  final String organizationId;
  final String reportedBy;
  final String siteId;
  final String type;
  final IncidentSeverity severity;
  final String description;
  final double? latitude;
  final double? longitude;
  final IncidentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  const Incident({
    required this.incidentId,
    required this.organizationId,
    required this.reportedBy,
    required this.siteId,
    required this.type,
    required this.severity,
    required this.description,
    this.latitude,
    this.longitude,
    this.status = IncidentStatus.open,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  /// Factory for creating and validating a brand-new incident report in the [IncidentStatus.open] state.
  factory Incident.create({
    required String incidentId,
    required String organizationId,
    required String reportedBy,
    required String siteId,
    required String type,
    required IncidentSeverity severity,
    required String description,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();
    final incident = Incident(
      incidentId: incidentId,
      organizationId: organizationId,
      reportedBy: reportedBy,
      siteId: siteId,
      type: type,
      severity: severity,
      description: description,
      latitude: latitude,
      longitude: longitude,
      status: IncidentStatus.open,
      createdAt: now,
      updatedAt: now,
    );
    return IncidentValidator.validate(incident);
  }

  /// Whether this incident has an associated geographic location.
  bool get hasLocation => latitude != null && longitude != null;

  /// Transitions this incident to [IncidentStatus.investigating].
  ///
  /// Throws [InvalidStatusTransitionFailure] if transition from current [status] is illegal.
  Incident investigate({DateTime? updatedAt}) {
    IncidentValidator.validateStatusTransition(
      from: status,
      to: IncidentStatus.investigating,
    );

    final updated = copyWith(
      status: IncidentStatus.investigating,
      updatedAt: updatedAt ?? DateTime.now(),
    );
    return IncidentValidator.validate(updated);
  }

  /// Transitions this incident to [IncidentStatus.resolved].
  ///
  /// Requires a valid [resolvedBy] identifier.
  /// Throws [IncidentAlreadyResolvedFailure] if the incident is already resolved.
  /// Throws [InvalidStatusTransitionFailure] if transition from current [status] is illegal.
  Incident resolve({
    required String resolvedBy,
    DateTime? resolvedAt,
    DateTime? updatedAt,
  }) {
    if (status == IncidentStatus.resolved) {
      throw const IncidentAlreadyResolvedFailure();
    }

    IncidentValidator.validateStatusTransition(
      from: status,
      to: IncidentStatus.resolved,
    );

    final resolvedTimestamp = resolvedAt ?? DateTime.now();
    final updatedTimestamp = updatedAt ?? resolvedTimestamp;

    final updated = copyWith(
      status: IncidentStatus.resolved,
      resolvedBy: resolvedBy,
      resolvedAt: resolvedTimestamp,
      updatedAt: updatedTimestamp,
    );
    return IncidentValidator.validate(updated);
  }

  /// Updates mutable non-lifecycle details of the incident while preserving identity and tenant ownership.
  Incident updateDetails({
    String? description,
    IncidentSeverity? severity,
    double? latitude,
    double? longitude,
    DateTime? updatedAt,
  }) {
    final updated = copyWith(
      description: description ?? this.description,
      severity: severity ?? this.severity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      updatedAt: updatedAt ?? DateTime.now(),
    );
    return IncidentValidator.validate(updated);
  }

  /// Creates a copy of this [Incident] with the given fields replaced by the new values.
  Incident copyWith({
    String? incidentId,
    String? organizationId,
    String? reportedBy,
    String? siteId,
    String? type,
    IncidentSeverity? severity,
    String? description,
    double? latitude,
    double? longitude,
    IncidentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? resolvedBy,
  }) {
    return Incident(
      incidentId: incidentId ?? this.incidentId,
      organizationId: organizationId ?? this.organizationId,
      reportedBy: reportedBy ?? this.reportedBy,
      siteId: siteId ?? this.siteId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
    );
  }

  /// Serializes this [Incident] into a canonical key-value Map.
  Map<String, dynamic> toMap() {
    return {
      'incidentId': incidentId,
      'organizationId': organizationId,
      'reportedBy': reportedBy,
      'siteId': siteId,
      'type': type,
      'severity': severity.toMapString(),
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.toMapString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolvedBy': resolvedBy,
    };
  }

  /// Deserializes a Map into a validated [Incident].
  ///
  /// Employs defensive parsing: malformed or missing fields throw explicit domain failures
  /// instead of silently substituting default values.
  factory Incident.fromMap(Map<String, dynamic> map, [String? fallbackId]) {
    // 1. Validate and extract required string identifiers
    final rawId = (map['incidentId'] as String?) ?? fallbackId;
    if (rawId == null || rawId.trim().isEmpty) {
      throw const InvalidIncidentIdFailure(
        'Missing or invalid incidentId in serialized data.',
      );
    }

    final rawOrgId = map['organizationId'];
    if (rawOrgId is! String || rawOrgId.trim().isEmpty) {
      throw const InvalidOrganizationIdFailure(
        'Missing or invalid organizationId in serialized data.',
      );
    }

    final rawReporterId = map['reportedBy'];
    if (rawReporterId is! String || rawReporterId.trim().isEmpty) {
      throw const InvalidReporterIdFailure(
        'Missing or invalid reportedBy in serialized data.',
      );
    }

    final rawSiteId = map['siteId'];
    if (rawSiteId is! String || rawSiteId.trim().isEmpty) {
      throw const InvalidSiteIdFailure(
        'Missing or invalid siteId in serialized data.',
      );
    }

    final rawType = map['type'];
    if (rawType is! String || rawType.trim().isEmpty) {
      throw const InvalidIncidentTypeFailure(
        'Missing or invalid type in serialized data.',
      );
    }

    final rawDesc = map['description'];
    if (rawDesc is! String || rawDesc.trim().isEmpty) {
      throw const InvalidIncidentDescriptionFailure(
        'Missing or invalid description in serialized data.',
      );
    }

    // 2. Validate and parse enums
    final rawSeverity = map['severity'];
    if (rawSeverity is! String || rawSeverity.trim().isEmpty) {
      throw const InvalidIncidentSeverityFailure(
        'Missing severity in serialized data.',
      );
    }
    final severity = IncidentSeverity.fromMapString(rawSeverity);

    final rawStatus = map['status'];
    if (rawStatus is! String || rawStatus.trim().isEmpty) {
      throw const InvalidIncidentStatusFailure(
        'Missing status in serialized data.',
      );
    }
    final status = IncidentStatus.fromMapString(rawStatus);

    // 3. Validate and parse coordinates
    double? parseCoordinate(dynamic val, String fieldName) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) {
        final parsed = double.tryParse(val);
        if (parsed != null) return parsed;
        throw InvalidCoordinatesFailure(
          'Non-numeric coordinate value for $fieldName: "$val".',
        );
      }
      throw InvalidCoordinatesFailure(
        'Invalid coordinate type for $fieldName: ${val.runtimeType}.',
      );
    }

    final lat = parseCoordinate(map['latitude'], 'latitude');
    final lng = parseCoordinate(map['longitude'], 'longitude');

    // 4. Validate and parse timestamps
    DateTime parseDate(dynamic val, String fieldName) {
      if (val == null) {
        throw InvalidIncidentTimestampFailure(
          'Missing timestamp for $fieldName in serialized data.',
        );
      }
      if (val is DateTime) return val;
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
        throw InvalidIncidentTimestampFailure(
          'Unparseable date string for $fieldName: "$val".',
        );
      }
      try {
        return (val as dynamic).toDate();
      } catch (_) {
        throw InvalidIncidentTimestampFailure(
          'Cannot convert $fieldName of type ${val.runtimeType} to DateTime.',
        );
      }
    }

    final createdAt = parseDate(map['createdAt'], 'createdAt');
    final updatedAt = parseDate(map['updatedAt'], 'updatedAt');

    DateTime? resolvedAt;
    if (map['resolvedAt'] != null) {
      resolvedAt = parseDate(map['resolvedAt'], 'resolvedAt');
    }

    final resolvedBy = map['resolvedBy'] as String?;

    final incident = Incident(
      incidentId: rawId,
      organizationId: rawOrgId,
      reportedBy: rawReporterId,
      siteId: rawSiteId,
      type: rawType,
      severity: severity,
      description: rawDesc,
      latitude: lat,
      longitude: lng,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      resolvedAt: resolvedAt,
      resolvedBy: resolvedBy,
    );

    return IncidentValidator.validate(incident);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Incident &&
        other.incidentId == incidentId &&
        other.organizationId == organizationId &&
        other.reportedBy == reportedBy &&
        other.siteId == siteId &&
        other.type == type &&
        other.severity == severity &&
        other.description == description &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.resolvedAt == resolvedAt &&
        other.resolvedBy == resolvedBy;
  }

  @override
  int get hashCode {
    return Object.hash(
      incidentId,
      organizationId,
      reportedBy,
      siteId,
      type,
      severity,
      description,
      latitude,
      longitude,
      status,
      createdAt,
      updatedAt,
      resolvedAt,
      resolvedBy,
    );
  }

  @override
  String toString() {
    return 'Incident('
        'id: $incidentId, '
        'org: $organizationId, '
        'type: $type, '
        'severity: ${severity.name.toUpperCase()}, '
        'status: ${status.name.toUpperCase()}, '
        'site: $siteId, '
        'reporter: $reportedBy'
        ')';
  }
}

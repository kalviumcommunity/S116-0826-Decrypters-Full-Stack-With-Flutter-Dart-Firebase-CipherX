import 'package:meta/meta.dart';

enum OperationalAlertType {
  missedShift,
  lateCheckIn,
  understaffedSite,
  criticalIncident,
  other;

  String get displayName {
    switch (this) {
      case OperationalAlertType.missedShift:
        return 'Missed Shift';
      case OperationalAlertType.lateCheckIn:
        return 'Late Check-In';
      case OperationalAlertType.understaffedSite:
        return 'Understaffed Site';
      case OperationalAlertType.criticalIncident:
        return 'Critical Incident';
      case OperationalAlertType.other:
        return 'Operational Notice';
    }
  }

  String toMapString() => name;

  static OperationalAlertType fromMapString(String value) {
    switch (value.toLowerCase()) {
      case 'missedshift':
      case 'missed_shift':
        return OperationalAlertType.missedShift;
      case 'latecheckin':
      case 'late_check_in':
      case 'late_checkin':
        return OperationalAlertType.lateCheckIn;
      case 'understaffedsite':
      case 'understaffed_site':
        return OperationalAlertType.understaffedSite;
      case 'criticalincident':
      case 'critical_incident':
        return OperationalAlertType.criticalIncident;
      case 'other':
      default:
        return OperationalAlertType.other;
    }
  }
}

enum AlertSeverity {
  info,
  warning,
  critical;

  String get displayName {
    switch (this) {
      case AlertSeverity.info:
        return 'Info';
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }

  String toMapString() => name;

  static AlertSeverity fromMapString(String value) {
    switch (value.toLowerCase()) {
      case 'info':
        return AlertSeverity.info;
      case 'warning':
        return AlertSeverity.warning;
      case 'critical':
        return AlertSeverity.critical;
      default:
        return AlertSeverity.info;
    }
  }
}

enum AlertStatus {
  active,
  acknowledged,
  resolved;

  String get displayName {
    switch (this) {
      case AlertStatus.active:
        return 'Active';
      case AlertStatus.acknowledged:
        return 'Acknowledged';
      case AlertStatus.resolved:
        return 'Resolved';
    }
  }

  String toMapString() => name;

  static AlertStatus fromMapString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return AlertStatus.active;
      case 'acknowledged':
        return AlertStatus.acknowledged;
      case 'resolved':
        return AlertStatus.resolved;
      default:
        return AlertStatus.active;
    }
  }
}

@immutable
class OperationalAlert {
  final String alertId;
  final String organizationId;
  final String? siteId;
  final OperationalAlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final AlertStatus status;
  final DateTime? timestamp;
  final DateTime? createdAt;

  const OperationalAlert({
    required this.alertId,
    required this.organizationId,
    this.siteId,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.status = AlertStatus.active,
    this.timestamp,
    this.createdAt,
  });

  OperationalAlert copyWith({
    String? alertId,
    String? organizationId,
    String? siteId,
    OperationalAlertType? type,
    AlertSeverity? severity,
    String? title,
    String? message,
    AlertStatus? status,
    DateTime? timestamp,
    DateTime? createdAt,
  }) {
    return OperationalAlert(
      alertId: alertId ?? this.alertId,
      organizationId: organizationId ?? this.organizationId,
      siteId: siteId ?? this.siteId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'alertId': alertId,
      'organizationId': organizationId,
      if (siteId != null) 'siteId': siteId,
      'type': type.toMapString(),
      'severity': severity.toMapString(),
      'title': title,
      'message': message,
      'status': status.toMapString(),
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  factory OperationalAlert.fromMap(
    Map<String, dynamic> map, [
    String? fallbackId,
  ]) {
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

    return OperationalAlert(
      alertId: (map['alertId'] as String?) ?? fallbackId ?? '',
      organizationId: (map['organizationId'] as String?) ?? '',
      siteId: map['siteId'] as String?,
      type: OperationalAlertType.fromMapString(
          (map['type'] as String?) ?? 'other'),
      severity:
          AlertSeverity.fromMapString((map['severity'] as String?) ?? 'info'),
      title: (map['title'] as String?) ?? 'Alert',
      message: (map['message'] as String?) ?? '',
      status: AlertStatus.fromMapString((map['status'] as String?) ?? 'active'),
      timestamp: map['timestamp'] != null ? parseDate(map['timestamp']) : null,
      createdAt: map['createdAt'] != null ? parseDate(map['createdAt']) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OperationalAlert &&
        other.alertId == alertId &&
        other.organizationId == organizationId &&
        other.siteId == siteId &&
        other.type == type &&
        other.severity == severity &&
        other.title == title &&
        other.message == message &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      alertId,
      organizationId,
      siteId,
      type,
      severity,
      title,
      message,
      status,
    );
  }
}

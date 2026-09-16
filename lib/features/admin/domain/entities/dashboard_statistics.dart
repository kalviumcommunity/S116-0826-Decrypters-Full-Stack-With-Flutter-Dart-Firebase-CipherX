import 'package:meta/meta.dart';

/// Pure domain entity holding real-time operational statistics for the Command Center.
///
/// Fully tenant-isolated and computed from authoritative domain models.
@immutable
class DashboardStatistics {
  final int totalGuards;
  final int onDutyGuards;
  final int absentGuards;
  final int lateGuards;
  final int activeSites;
  final int openIncidents;
  final int criticalAlerts;

  const DashboardStatistics({
    required this.totalGuards,
    required this.onDutyGuards,
    required this.absentGuards,
    required this.lateGuards,
    required this.activeSites,
    required this.openIncidents,
    required this.criticalAlerts,
  });

  const DashboardStatistics.empty()
      : totalGuards = 0,
        onDutyGuards = 0,
        absentGuards = 0,
        lateGuards = 0,
        activeSites = 0,
        openIncidents = 0,
        criticalAlerts = 0;

  DashboardStatistics copyWith({
    int? totalGuards,
    int? onDutyGuards,
    int? absentGuards,
    int? lateGuards,
    int? activeSites,
    int? openIncidents,
    int? criticalAlerts,
  }) {
    return DashboardStatistics(
      totalGuards: totalGuards ?? this.totalGuards,
      onDutyGuards: onDutyGuards ?? this.onDutyGuards,
      absentGuards: absentGuards ?? this.absentGuards,
      lateGuards: lateGuards ?? this.lateGuards,
      activeSites: activeSites ?? this.activeSites,
      openIncidents: openIncidents ?? this.openIncidents,
      criticalAlerts: criticalAlerts ?? this.criticalAlerts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalGuards': totalGuards,
      'onDutyGuards': onDutyGuards,
      'absentGuards': absentGuards,
      'lateGuards': lateGuards,
      'activeSites': activeSites,
      'openIncidents': openIncidents,
      'criticalAlerts': criticalAlerts,
    };
  }

  factory DashboardStatistics.fromMap(Map<String, dynamic> map) {
    return DashboardStatistics(
      totalGuards: (map['totalGuards'] as num?)?.toInt() ?? 0,
      onDutyGuards: (map['onDutyGuards'] as num?)?.toInt() ?? 0,
      absentGuards: (map['absentGuards'] as num?)?.toInt() ?? 0,
      lateGuards: (map['lateGuards'] as num?)?.toInt() ?? 0,
      activeSites: (map['activeSites'] as num?)?.toInt() ?? 0,
      openIncidents: (map['openIncidents'] as num?)?.toInt() ?? 0,
      criticalAlerts: (map['criticalAlerts'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardStatistics &&
        other.totalGuards == totalGuards &&
        other.onDutyGuards == onDutyGuards &&
        other.absentGuards == absentGuards &&
        other.lateGuards == lateGuards &&
        other.activeSites == activeSites &&
        other.openIncidents == openIncidents &&
        other.criticalAlerts == criticalAlerts;
  }

  @override
  int get hashCode => Object.hash(
        totalGuards,
        onDutyGuards,
        absentGuards,
        lateGuards,
        activeSites,
        openIncidents,
        criticalAlerts,
      );
}

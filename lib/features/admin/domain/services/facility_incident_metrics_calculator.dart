import '../../../alerts/domain/entities/alert.dart';
import '../../../alerts/domain/entities/alert_status.dart';
import '../../../alerts/domain/entities/alert_type.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/domain/entities/incident_status.dart';
import '../../../sites/domain/entities/site.dart';

/// Calculation service for facility, incident, and alert metrics.
class FacilityIncidentMetricsCalculator {
  const FacilityIncidentMetricsCalculator();

  /// Calculates total active sites.
  int calculateActiveSites(List<Site> sites) {
    return sites.where((s) => s.status == SiteStatus.active).length;
  }

  /// Calculates total open incidents.
  int calculateOpenIncidents(List<Incident> incidents) {
    return incidents.where((i) => i.status == IncidentStatus.open).length;
  }

  /// Calculates total active critical alerts.
  int calculateCriticalAlerts(List<Alert> alerts) {
    return alerts.where((a) {
      return a.type == AlertType.criticalIncident &&
          a.status == AlertStatus.active;
    }).length;
  }
}

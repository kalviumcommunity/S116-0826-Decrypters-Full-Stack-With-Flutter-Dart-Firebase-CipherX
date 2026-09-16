import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/domain/entities/incident_severity.dart';
import '../entities/alert.dart';
import '../entities/alert_type.dart';
import '../services/alert_id_generator.dart';
import 'alert_rule.dart';

class CriticalIncidentInput {
  final Incident incident;
  final String targetOrganizationId;

  const CriticalIncidentInput({
    required this.incident,
    required this.targetOrganizationId,
  });
}

class CriticalIncidentRule implements AlertRule<CriticalIncidentInput> {
  const CriticalIncidentRule();

  @override
  String get ruleName => 'CRITICAL_INCIDENT';

  @override
  Future<Alert?> evaluate(
    CriticalIncidentInput input, {
    required DateTime evaluationTime,
  }) async {
    final incident = input.incident;

    // Tenant boundary check
    if (incident.organizationId != input.targetOrganizationId) {
      return null;
    }

    // Only alert on critical severity
    if (incident.severity != IncidentSeverity.critical) {
      return null;
    }

    final alertId = AlertIdGenerator.criticalIncident(
      incident.organizationId,
      incident.incidentId,
    );

    return Alert(
      alertId: alertId,
      organizationId: incident.organizationId,
      type: AlertType.criticalIncident,
      sourceEntityId: incident.incidentId,
      sourceEntityType: 'incident',
      createdAt: evaluationTime,
      metadata: {
        'incidentId': incident.incidentId,
        'siteId': incident.siteId,
        'type': incident.type,
        'severity': incident.severity.toMapString(),
        'reportedBy': incident.reportedBy,
      },
    );
  }
}

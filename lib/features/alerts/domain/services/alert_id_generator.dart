/// Generates deterministic, collision-resistant alert IDs for idempotency.
class AlertIdGenerator {
  static String missedShift(String orgId, String shiftId) =>
      'alert_${orgId.trim()}_${shiftId.trim()}_missed_shift';

  static String lateCheckIn(String orgId, String shiftId) =>
      'alert_${orgId.trim()}_${shiftId.trim()}_late_check_in';

  static String understaffedSite(String orgId, String siteId, String windowKey) =>
      'alert_${orgId.trim()}_${siteId.trim()}_understaffed_${windowKey.trim()}';

  static String criticalIncident(String orgId, String incidentId) =>
      'alert_${orgId.trim()}_${incidentId.trim()}_critical_incident';
}

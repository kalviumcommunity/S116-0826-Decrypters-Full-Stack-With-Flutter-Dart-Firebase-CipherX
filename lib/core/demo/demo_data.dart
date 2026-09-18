import '../../features/guards/domain/entities/guard.dart';
import '../../features/sites/domain/entities/site.dart';
import '../../features/shifts/domain/entities/shift.dart';
import '../../features/shifts/domain/entities/shift_time.dart';
import '../../features/incidents/domain/entities/incident.dart';
import '../../features/incidents/domain/entities/incident_severity.dart';
import '../../features/incidents/domain/entities/incident_status.dart';

/// Safe demo data definitions for evaluator demonstrations and tests.
///
/// Contains zero real passwords, tokens, or private credentials.
class DemoData {
  static const String demoOrgId = 'demo-cipher-org';

  // Demo Sites
  static const Site siteCyberGateway = Site(
    siteId: 'site-demo-01',
    organizationId: demoOrgId,
    name: 'Cyber Gateway Tech Park',
    address: 'Hitech City, Madhapur, Hyderabad',
    latitude: 17.4483,
    longitude: 78.3742,
    geofenceRadius: 75.0,
    status: SiteStatus.active,
  );

  static const Site siteFinancialTower = Site(
    siteId: 'site-demo-02',
    organizationId: demoOrgId,
    name: 'Financial District Tower',
    address: 'Gachibowli, Hyderabad',
    latitude: 17.4156,
    longitude: 78.3425,
    geofenceRadius: 60.0,
    status: SiteStatus.active,
  );

  // Demo Guards
  static const Guard guardRahul = Guard(
    guardId: 'guard-demo-01',
    organizationId: demoOrgId,
    name: 'Rahul Sharma',
    employeeId: 'CX-1001',
    phone: '+91 98765 43210',
    status: GuardStatus.active,
  );

  static const Guard guardVikram = Guard(
    guardId: 'guard-demo-02',
    organizationId: demoOrgId,
    name: 'Vikram Singh',
    employeeId: 'CX-1002',
    phone: '+91 98765 43211',
    status: GuardStatus.active,
  );

  // Demo Shifts
  static Shift morningShift = Shift(
    shiftId: 'shift-demo-01',
    organizationId: demoOrgId,
    siteId: siteCyberGateway.siteId,
    guardId: guardRahul.guardId,
    date: DateTime.now(),
    startTime: const ShiftTime(hour: 8, minute: 0),
    endTime: const ShiftTime(hour: 16, minute: 0),
    status: ShiftStatus.scheduled,
  );

  // Demo Incidents
  static Incident openIncident = Incident(
    incidentId: 'inc-demo-01',
    organizationId: demoOrgId,
    reportedBy: guardRahul.guardId,
    siteId: siteCyberGateway.siteId,
    type: 'Unauthorized Entry Attempt',
    severity: IncidentSeverity.high,
    description:
        'Individual attempted perimeter breach at North Gate without access badge.',
    status: IncidentStatus.open,
    createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    updatedAt: DateTime.now().subtract(const Duration(minutes: 45)),
  );
}

import 'dart:async';

import '../../features/alerts/domain/entities/alert.dart';
import '../../features/alerts/domain/entities/alert_status.dart';
import '../../features/alerts/domain/entities/alert_type.dart';
import '../../features/attendance/domain/entities/attendance_record.dart';
import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/guards/domain/entities/guard.dart';
import '../../features/identity/domain/entities/organization.dart';
import '../../features/identity/domain/entities/user_profile.dart';
import '../../features/incidents/domain/entities/incident.dart';
import '../../features/incidents/domain/entities/incident_severity.dart';
import '../../features/incidents/domain/entities/incident_status.dart';
import '../../features/location/domain/entities/location_data.dart';
import '../../features/shifts/domain/entities/shift.dart';
import '../../features/shifts/domain/entities/shift_time.dart';
import '../../features/sites/domain/entities/site.dart';

/// Complete in-memory demonstration suite and safe sample data for Cipher-X.
///
/// Ensures 100% reliable, zero-failure offline presentation and evaluation
/// across Admin, Guard, and Supervisor operational workflows.
class DemoData {
  static const String demoOrgId = 'demo-cipher-org';

  // Demo Credentials & Accounts
  static const String adminEmail = 'admin@cipherx.org';
  static const String guardEmail = 'guard@cipherx.org';
  static const String supervisorEmail = 'supervisor@cipherx.org';

  static const String adminUid = 'demo-admin-uid';
  static const String guardUid = 'guard-demo-01';
  static const String supervisorUid = 'demo-supervisor-uid';

  static const AuthUser authUserAdmin = AuthUser(
    uid: adminUid,
    email: adminEmail,
    displayName: 'Aditi Rao (Commander)',
    emailVerified: true,
  );

  static const AuthUser authUserGuard = AuthUser(
    uid: guardUid,
    email: guardEmail,
    displayName: 'Rahul Sharma (Guard)',
    emailVerified: true,
  );

  static const AuthUser authUserSupervisor = AuthUser(
    uid: supervisorUid,
    email: supervisorEmail,
    displayName: 'Suresh Mehta (Supervisor)',
    emailVerified: true,
  );

  static const Organization demoOrganization = Organization(
    id: demoOrgId,
    name: 'CipherX Security Operations',
    code: 'CX-DEMO-2026',
    status: OrganizationStatus.active,
  );

  static const UserProfile profileAdmin = UserProfile(
    uid: adminUid,
    email: adminEmail,
    displayName: 'Aditi Rao (Commander)',
    phone: '+91 98765 00001',
    organizationId: demoOrgId,
    role: UserRole.admin,
    status: UserStatus.active,
  );

  static const UserProfile profileGuard = UserProfile(
    uid: guardUid,
    email: guardEmail,
    displayName: 'Rahul Sharma (Guard)',
    phone: '+91 98765 43210',
    organizationId: demoOrgId,
    role: UserRole.guard,
    status: UserStatus.active,
  );

  static const UserProfile profileSupervisor = UserProfile(
    uid: supervisorUid,
    email: supervisorEmail,
    displayName: 'Suresh Mehta (Supervisor)',
    phone: '+91 98765 00002',
    organizationId: demoOrgId,
    role: UserRole.supervisor,
    status: UserStatus.active,
  );

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
    email: guardEmail,
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

  static Shift eveningShift = Shift(
    shiftId: 'shift-demo-02',
    organizationId: demoOrgId,
    siteId: siteFinancialTower.siteId,
    guardId: guardVikram.guardId,
    date: DateTime.now(),
    startTime: const ShiftTime(hour: 16, minute: 0),
    endTime: const ShiftTime(hour: 23, minute: 59),
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

  static Incident resolvedIncident = Incident(
    incidentId: 'inc-demo-02',
    organizationId: demoOrgId,
    reportedBy: guardVikram.guardId,
    siteId: siteFinancialTower.siteId,
    type: 'Access Badge Scanner Delay',
    severity: IncidentSeverity.low,
    description: 'RFID reader calibrated and restarted successfully.',
    status: IncidentStatus.resolved,
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
  );

  // Demo Alert
  static Alert demoAlert = Alert(
    alertId: 'alert-demo-01',
    organizationId: demoOrgId,
    type: AlertType.criticalIncident,
    sourceEntityId: 'inc-demo-01',
    sourceEntityType: 'incident',
    createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    status: AlertStatus.active,
    metadata: const {'siteName': 'Cyber Gateway Tech Park'},
  );

  // Demo Attendance
  static AttendanceRecord demoAttendance = AttendanceRecord(
    attendanceId: 'att-demo-01',
    organizationId: demoOrgId,
    shiftId: 'shift-demo-01',
    siteId: 'site-demo-01',
    guardId: 'guard-demo-01',
    checkInTime: DateTime.now().subtract(const Duration(hours: 2)),
    status: AttendanceStatus.active,
    verificationMethod: 'qr_gps_geofence',
    checkInLocation: LocationData(
      latitude: 17.4483,
      longitude: 78.3742,
      accuracy: 5.0,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  );

  // In-Memory Presentation Store
  static final List<Site> _sites = [siteCyberGateway, siteFinancialTower];
  static final StreamController<List<Site>> _sitesController =
      StreamController<List<Site>>.broadcast();

  static final List<Guard> _guards = [guardRahul, guardVikram];
  static final StreamController<List<Guard>> _guardsController =
      StreamController<List<Guard>>.broadcast();

  static final List<Shift> _shifts = [morningShift, eveningShift];
  static final StreamController<List<Shift>> _shiftsController =
      StreamController<List<Shift>>.broadcast();

  static final List<Incident> _incidents = [openIncident, resolvedIncident];
  static final StreamController<List<Incident>> _incidentsController =
      StreamController<List<Incident>>.broadcast();

  static final List<Alert> _alerts = [demoAlert];
  static final StreamController<List<Alert>> _alertsController =
      StreamController<List<Alert>>.broadcast();

  static final List<AttendanceRecord> _attendances = [demoAttendance];
  static final StreamController<List<AttendanceRecord>> _attendancesController =
      StreamController<List<AttendanceRecord>>.broadcast();

  // Helper Checkers
  static bool isDemoOrg(String? orgId) {
    if (orgId == null || orgId.trim().isEmpty) return true;
    return orgId.trim() == demoOrgId;
  }

  static bool isDemoUid(String? uid) {
    if (uid == null) return false;
    return uid == adminUid ||
        uid == guardUid ||
        uid == supervisorUid ||
        uid.startsWith('demo-') ||
        uid.startsWith('guard-demo');
  }

  static UserProfile getDemoProfile(String uid) {
    if (uid == guardUid || uid.contains('guard')) {
      return profileGuard;
    }
    if (uid == supervisorUid || uid.contains('supervisor')) {
      return profileSupervisor;
    }
    return profileAdmin;
  }

  // Sites Operations
  static List<Site> getSites({bool includeInactive = false}) {
    if (includeInactive) return List.unmodifiable(_sites);
    return List.unmodifiable(
      _sites.where((s) => s.status == SiteStatus.active),
    );
  }

  static Stream<List<Site>> watchSites({bool includeInactive = false}) async* {
    yield getSites(includeInactive: includeInactive);
    yield* _sitesController.stream.map((list) {
      if (includeInactive) return list;
      return list.where((s) => s.status == SiteStatus.active).toList();
    });
  }

  static Site? getSite(String siteId) {
    for (final s in _sites) {
      if (s.siteId == siteId) return s;
    }
    return null;
  }

  static Site addSite(Site site) {
    final assigned = site.siteId.trim().isNotEmpty
        ? site
        : site.copyWith(siteId: 'site-demo-');
    _sites.removeWhere((s) => s.siteId == assigned.siteId);
    _sites.add(assigned);
    _sitesController.add(List.unmodifiable(_sites));
    return assigned;
  }

  static Site updateSite(Site site) {
    final index = _sites.indexWhere((s) => s.siteId == site.siteId);
    if (index != -1) {
      _sites[index] = site;
    } else {
      _sites.add(site);
    }
    _sitesController.add(List.unmodifiable(_sites));
    return site;
  }

  static void deleteSite(String siteId) {
    final index = _sites.indexWhere((s) => s.siteId == siteId);
    if (index != -1) {
      _sites[index] = _sites[index].copyWith(status: SiteStatus.inactive);
      _sitesController.add(List.unmodifiable(_sites));
    }
  }

  // Guards Operations
  static List<Guard> getGuards({bool includeInactive = false}) {
    if (includeInactive) return List.unmodifiable(_guards);
    return List.unmodifiable(
      _guards.where((g) => g.status == GuardStatus.active),
    );
  }

  static Stream<List<Guard>> watchGuards(
      {bool includeInactive = false}) async* {
    yield getGuards(includeInactive: includeInactive);
    yield* _guardsController.stream.map((list) {
      if (includeInactive) return list;
      return list.where((g) => g.status == GuardStatus.active).toList();
    });
  }

  static Guard? getGuard(String guardId) {
    for (final g in _guards) {
      if (g.guardId == guardId) return g;
    }
    return null;
  }

  static Guard addGuard(Guard guard) {
    final assigned = guard.guardId.trim().isNotEmpty
        ? guard
        : guard.copyWith(guardId: 'guard-demo-');
    _guards.removeWhere((g) => g.guardId == assigned.guardId);
    _guards.add(assigned);
    _guardsController.add(List.unmodifiable(_guards));
    return assigned;
  }

  static Guard updateGuard(Guard guard) {
    final index = _guards.indexWhere((g) => g.guardId == guard.guardId);
    if (index != -1) {
      _guards[index] = guard;
    } else {
      _guards.add(guard);
    }
    _guardsController.add(List.unmodifiable(_guards));
    return guard;
  }

  static void deleteGuard(String guardId) {
    final index = _guards.indexWhere((g) => g.guardId == guardId);
    if (index != -1) {
      _guards[index] = _guards[index].copyWith(status: GuardStatus.inactive);
      _guardsController.add(List.unmodifiable(_guards));
    }
  }

  // Shifts Operations
  static List<Shift> getShifts() => List.unmodifiable(_shifts);

  static Stream<List<Shift>> watchShifts() async* {
    yield getShifts();
    yield* _shiftsController.stream;
  }

  static List<Shift> getShiftsByGuard(String guardId) {
    return List.unmodifiable(_shifts.where((s) => s.guardId == guardId));
  }

  static Stream<List<Shift>> watchShiftsByGuard(String guardId) async* {
    yield getShiftsByGuard(guardId);
    yield* _shiftsController.stream.map(
      (list) => list.where((s) => s.guardId == guardId).toList(),
    );
  }

  static Shift? getShift(String shiftId) {
    for (final s in _shifts) {
      if (s.shiftId == shiftId) return s;
    }
    return null;
  }

  static Shift addShift(Shift shift) {
    final assigned = shift.shiftId.trim().isNotEmpty
        ? shift
        : shift.copyWith(shiftId: 'shift-demo-');
    _shifts.removeWhere((s) => s.shiftId == assigned.shiftId);
    _shifts.add(assigned);
    _shiftsController.add(List.unmodifiable(_shifts));
    return assigned;
  }

  static Shift updateShift(Shift shift) {
    final index = _shifts.indexWhere((s) => s.shiftId == shift.shiftId);
    if (index != -1) {
      _shifts[index] = shift;
    } else {
      _shifts.add(shift);
    }
    _shiftsController.add(List.unmodifiable(_shifts));
    return shift;
  }

  // Incidents Operations
  static List<Incident> getIncidents() => List.unmodifiable(_incidents);

  static Stream<List<Incident>> watchIncidents() async* {
    yield getIncidents();
    yield* _incidentsController.stream;
  }

  static Incident addIncident(Incident incident) {
    final assigned = incident.incidentId.trim().isNotEmpty
        ? incident
        : incident.copyWith(incidentId: 'inc-demo-');
    _incidents.removeWhere((i) => i.incidentId == assigned.incidentId);
    _incidents.insert(0, assigned);
    _incidentsController.add(List.unmodifiable(_incidents));
    return assigned;
  }

  // Attendance Operations
  static List<AttendanceRecord> getAttendances() =>
      List.unmodifiable(_attendances);

  static Stream<List<AttendanceRecord>> watchAttendances() async* {
    yield getAttendances();
    yield* _attendancesController.stream;
  }

  static AttendanceRecord addAttendance(AttendanceRecord record) {
    final assigned = record.attendanceId.trim().isNotEmpty
        ? record
        : record.copyWith(
            attendanceId: 'att-demo-',
          );
    _attendances.removeWhere((a) => a.attendanceId == assigned.attendanceId);
    _attendances.insert(0, assigned);
    _attendancesController.add(List.unmodifiable(_attendances));
    return assigned;
  }

  // Alerts Operations
  static List<Alert> getAlerts() => List.unmodifiable(_alerts);

  static Stream<List<Alert>> watchAlerts() async* {
    yield getAlerts();
    yield* _alertsController.stream;
  }

  static Alert addAlert(Alert alert) {
    _alerts.removeWhere((a) => a.alertId == alert.alertId);
    _alerts.insert(0, alert);
    _alertsController.add(List.unmodifiable(_alerts));
    return alert;
  }
}

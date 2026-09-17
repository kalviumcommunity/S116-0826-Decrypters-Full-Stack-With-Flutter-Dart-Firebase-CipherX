import 'dart:async';

import '../../../alerts/domain/entities/alert.dart';
import '../../../alerts/domain/repositories/alert_repository.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../../guards/domain/entities/guard.dart';
import '../../../guards/domain/repositories/guard_repository.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/domain/repositories/incident_repository.dart';
import '../../../shifts/domain/entities/shift.dart';
import '../../../shifts/domain/repositories/shift_repository.dart';
import '../../../sites/domain/entities/site.dart';
import '../../../sites/domain/repositories/site_repository.dart';
import '../../domain/entities/dashboard_statistics.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/services/dashboard_statistics_service.dart';

/// Production implementation of [DashboardRepository] that aggregates
/// domain data from 6 individual feature repositories with full tenant isolation.
class DashboardRepositoryImpl implements DashboardRepository {
  final GuardRepository _guardRepository;
  final ShiftRepository _shiftRepository;
  final AttendanceRepository _attendanceRepository;
  final SiteRepository _siteRepository;
  final IncidentRepository _incidentRepository;
  final AlertRepository _alertRepository;
  final DashboardStatisticsService _statisticsService;

  DashboardRepositoryImpl({
    required GuardRepository guardRepository,
    required ShiftRepository shiftRepository,
    required AttendanceRepository attendanceRepository,
    required SiteRepository siteRepository,
    required IncidentRepository incidentRepository,
    required AlertRepository alertRepository,
    DashboardStatisticsService? statisticsService,
  })  : _guardRepository = guardRepository,
        _shiftRepository = shiftRepository,
        _attendanceRepository = attendanceRepository,
        _siteRepository = siteRepository,
        _incidentRepository = incidentRepository,
        _alertRepository = alertRepository,
        _statisticsService =
            statisticsService ?? const DashboardStatisticsService();

  @override
  Future<DashboardStatistics> getStatistics({
    required String organizationId,
    DateTime? evaluationTime,
  }) async {
    final now = evaluationTime ?? DateTime.now();

    final results = await Future.wait([
      _guardRepository.getGuards(organizationId),
      _shiftRepository.getShiftsByOrganization(organizationId),
      _attendanceRepository.getAttendanceByOrganization(organizationId),
      _siteRepository.getSites(organizationId),
      _incidentRepository.getIncidentsByOrganization(organizationId),
      _alertRepository.getAlerts(organizationId: organizationId),
    ]);

    final guards = results[0] as List<Guard>;
    final shifts = results[1] as List<Shift>;
    final attendances = results[2] as List<AttendanceRecord>;
    final sites = results[3] as List<Site>;
    final incidents = results[4] as List<Incident>;
    final alerts = results[5] as List<Alert>;

    return _statisticsService.calculateStatistics(
      guards: guards,
      shifts: shifts,
      attendances: attendances,
      sites: sites,
      incidents: incidents,
      alerts: alerts,
      evaluationTime: now,
    );
  }

  @override
  Stream<DashboardStatistics> watchStatistics({
    required String organizationId,
    DateTime? evaluationTime,
  }) {
    late StreamController<DashboardStatistics> controller;
    final subscriptions = <StreamSubscription<dynamic>>[];

    List<Guard>? currentGuards;
    List<Shift>? currentShifts;
    List<AttendanceRecord>? currentAttendances;
    List<Site>? currentSites;
    List<Incident>? currentIncidents;
    List<Alert>? currentAlerts;

    void tryEmit() {
      if (controller.isClosed) return;
      final evalTime = evaluationTime ?? DateTime.now();
      final stats = _statisticsService.calculateStatistics(
        guards: currentGuards ?? const [],
        shifts: currentShifts ?? const [],
        attendances: currentAttendances ?? const [],
        sites: currentSites ?? const [],
        incidents: currentIncidents ?? const [],
        alerts: currentAlerts ?? const [],
        evaluationTime: evalTime,
      );
      controller.add(stats);
    }

    controller = StreamController<DashboardStatistics>(
      onListen: () {
        subscriptions.add(
          _guardRepository.watchGuards(organizationId).listen(
            (guards) {
              currentGuards = guards;
              tryEmit();
            },
            onError: controller.addError,
          ),
        );

        subscriptions.add(
          _shiftRepository.watchShiftsByOrganization(organizationId).listen(
            (shifts) {
              currentShifts = shifts;
              tryEmit();
            },
            onError: controller.addError,
          ),
        );

        subscriptions.add(
          _attendanceRepository
              .watchAttendanceByOrganization(organizationId)
              .listen(
            (attendances) {
              currentAttendances = attendances;
              tryEmit();
            },
            onError: controller.addError,
          ),
        );

        subscriptions.add(
          _siteRepository.watchSites(organizationId).listen(
            (sites) {
              currentSites = sites;
              tryEmit();
            },
            onError: controller.addError,
          ),
        );

        subscriptions.add(
          _incidentRepository
              .watchIncidentsByOrganization(organizationId)
              .listen(
            (incidents) {
              currentIncidents = incidents;
              tryEmit();
            },
            onError: controller.addError,
          ),
        );

        subscriptions.add(
          _alertRepository.watchAlerts(organizationId: organizationId).listen(
            (alerts) {
              currentAlerts = alerts;
              tryEmit();
            },
            onError: controller.addError,
          ),
        );
      },
      onCancel: () async {
        for (final sub in subscriptions) {
          await sub.cancel();
        }
        subscriptions.clear();
        await controller.close();
      },
    );

    return controller.stream;
  }
}

import 'dart:async';

import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../../shifts/domain/entities/shift.dart';
import '../../../shifts/domain/repositories/shift_repository.dart';
import '../../../sites/domain/entities/site.dart';
import '../../../sites/domain/repositories/site_repository.dart';
import '../../domain/entities/site_coverage_filter.dart';
import '../../domain/entities/site_coverage_item.dart';
import '../../domain/repositories/site_coverage_repository.dart';
import '../../domain/services/site_coverage_service.dart';

/// Production implementation of [SiteCoverageRepository] providing
/// real-time and snapshot site coverage analytics scoped by organization.
class SiteCoverageRepositoryImpl implements SiteCoverageRepository {
  final SiteRepository _siteRepository;
  final ShiftRepository _shiftRepository;
  final AttendanceRepository _attendanceRepository;
  final SiteCoverageService _coverageService;

  SiteCoverageRepositoryImpl({
    required SiteRepository siteRepository,
    required ShiftRepository shiftRepository,
    required AttendanceRepository attendanceRepository,
    SiteCoverageService? coverageService,
  })  : _siteRepository = siteRepository,
        _shiftRepository = shiftRepository,
        _attendanceRepository = attendanceRepository,
        _coverageService = coverageService ?? const SiteCoverageService();

  @override
  Future<List<SiteCoverageItem>> getSiteCoverage({
    required String organizationId,
    SiteCoverageFilter filter = SiteCoverageFilter.all,
    DateTime? evaluationTime,
  }) async {
    final now = evaluationTime ?? DateTime.now();

    final results = await Future.wait([
      _siteRepository.getSites(organizationId),
      _shiftRepository.getShiftsByOrganization(organizationId),
      _attendanceRepository.getAttendanceByOrganization(organizationId),
    ]);

    final sites = results[0] as List<Site>;
    final shifts = results[1] as List<Shift>;
    final attendances = results[2] as List<AttendanceRecord>;

    final activeAttendances = attendances
        .where((a) => a.status == AttendanceStatus.active && !a.isCheckedOut)
        .toList();

    final allItems = _coverageService.calculateAllCoverage(
      sites: sites,
      shifts: shifts,
      activeAttendances: activeAttendances,
      evaluationTime: now,
    );

    return _coverageService.filterCoverages(allItems, filter);
  }

  @override
  Stream<List<SiteCoverageItem>> watchSiteCoverage({
    required String organizationId,
    SiteCoverageFilter filter = SiteCoverageFilter.all,
    DateTime? evaluationTime,
  }) {
    late StreamController<List<SiteCoverageItem>> controller;
    final subscriptions = <StreamSubscription<dynamic>>[];

    List<Site>? currentSites;
    List<Shift>? currentShifts;
    List<AttendanceRecord>? currentAttendances;

    void tryEmit() {
      if (controller.isClosed) return;
      final evalTime = evaluationTime ?? DateTime.now();
      final activeAttendances = (currentAttendances ?? const [])
          .where((a) => a.status == AttendanceStatus.active && !a.isCheckedOut)
          .toList();

      final allItems = _coverageService.calculateAllCoverage(
        sites: currentSites ?? const [],
        shifts: currentShifts ?? const [],
        activeAttendances: activeAttendances,
        evaluationTime: evalTime,
      );

      final filtered = _coverageService.filterCoverages(allItems, filter);
      controller.add(filtered);
    }

    controller = StreamController<List<SiteCoverageItem>>(
      onListen: () {
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

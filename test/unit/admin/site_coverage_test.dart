import 'package:flutter_test/flutter_test.dart';

import 'package:cipher_x/features/admin/domain/entities/coverage_status.dart';
import 'package:cipher_x/features/admin/domain/entities/site_coverage_filter.dart';
import 'package:cipher_x/features/admin/domain/entities/site_coverage_item.dart';
import 'package:cipher_x/features/admin/domain/services/site_coverage_service.dart';
import 'package:cipher_x/features/attendance/domain/entities/attendance_record.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift_time.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';

void main() {
  group('CoverageStatus Enum Tests', () {
    test('displayName returns proper uppercase representation', () {
      expect(CoverageStatus.fullyStaffed.displayName, 'FULLY STAFFED');
      expect(CoverageStatus.understaffed.displayName, 'UNDERSTAFFED');
    });

    test('toMapString and fromMapString round-trip', () {
      expect(
        CoverageStatus.fromMapString(CoverageStatus.fullyStaffed.toMapString()),
        CoverageStatus.fullyStaffed,
      );
      expect(
        CoverageStatus.fromMapString(CoverageStatus.understaffed.toMapString()),
        CoverageStatus.understaffed,
      );
      expect(
        CoverageStatus.fromMapString('fully_staffed'),
        CoverageStatus.fullyStaffed,
      );
      expect(
        CoverageStatus.fromMapString('unknown_val'),
        CoverageStatus.understaffed,
      );
    });
  });

  group('SiteCoverageFilter Enum Tests', () {
    test('displayName returns human readable string', () {
      expect(SiteCoverageFilter.all.displayName, 'All');
      expect(SiteCoverageFilter.fullyStaffed.displayName, 'Fully Staffed');
      expect(SiteCoverageFilter.understaffed.displayName, 'Understaffed');
    });
  });

  group('SiteCoverageItem Entity Tests', () {
    test('deficit and boolean getters', () {
      const fullyStaffed = SiteCoverageItem(
        siteId: 's1',
        siteName: 'HQ Site',
        organizationId: 'org1',
        actualStaff: 3,
        requiredStaff: 3,
        status: CoverageStatus.fullyStaffed,
      );

      expect(fullyStaffed.isFullyStaffed, isTrue);
      expect(fullyStaffed.isUnderstaffed, isFalse);
      expect(fullyStaffed.deficit, 0);

      const understaffed = SiteCoverageItem(
        siteId: 's2',
        siteName: 'North Branch',
        organizationId: 'org1',
        actualStaff: 1,
        requiredStaff: 4,
        status: CoverageStatus.understaffed,
      );

      expect(understaffed.isFullyStaffed, isFalse);
      expect(understaffed.isUnderstaffed, isTrue);
      expect(understaffed.deficit, 3);
    });

    test('serialization toMap and fromMap', () {
      const original = SiteCoverageItem(
        siteId: 's1',
        siteName: 'Alpha Base',
        organizationId: 'org1',
        actualStaff: 2,
        requiredStaff: 3,
        status: CoverageStatus.understaffed,
      );

      final map = original.toMap();
      final deserialized = SiteCoverageItem.fromMap(map);

      expect(deserialized, equals(original));
      expect(deserialized.hashCode, equals(original.hashCode));
    });
  });

  group('SiteCoverageService Logic & Filtering Tests', () {
    const service = SiteCoverageService();
    final evalTime = DateTime(2026, 9, 17, 10, 0);

    const site1 = Site(
      siteId: 's1',
      organizationId: 'org1',
      name: 'Site 1',
      address: 'Address 1',
      latitude: 0,
      longitude: 0,
      geofenceRadius: 100,
    );

    test(
        'calculates coverage for site correctly based on scheduled shifts and active attendance',
        () {
      final shifts = [
        Shift(
          shiftId: 'sh1',
          guardId: 'g1',
          siteId: 's1',
          organizationId: 'org1',
          date: evalTime,
          startTime: const ShiftTime(hour: 8, minute: 0),
          endTime: const ShiftTime(hour: 16, minute: 0),
        ),
        Shift(
          shiftId: 'sh2',
          guardId: 'g2',
          siteId: 's1',
          organizationId: 'org1',
          date: evalTime,
          startTime: const ShiftTime(hour: 8, minute: 0),
          endTime: const ShiftTime(hour: 16, minute: 0),
        ),
      ];

      final activeAttendances = [
        AttendanceRecord(
          attendanceId: 'a1',
          guardId: 'g1',
          siteId: 's1',
          organizationId: 'org1',
          shiftId: 'sh1',
          checkInTime: evalTime.subtract(const Duration(hours: 1)),
          status: AttendanceStatus.active,
        ),
      ];

      final coverage = service.calculateCoverageForSite(
        site: site1,
        shifts: shifts,
        activeAttendances: activeAttendances,
        evaluationTime: evalTime,
      );

      expect(coverage.actualStaff, 1);
      expect(coverage.requiredStaff, 2);
      expect(coverage.status, CoverageStatus.understaffed);
    });

    test('filterCoverages filters items according to SiteCoverageFilter', () {
      const fullyStaffed = SiteCoverageItem(
        siteId: 's1',
        siteName: 'Site 1',
        organizationId: 'org1',
        actualStaff: 2,
        requiredStaff: 2,
        status: CoverageStatus.fullyStaffed,
      );

      const understaffed = SiteCoverageItem(
        siteId: 's2',
        siteName: 'Site 2',
        organizationId: 'org1',
        actualStaff: 1,
        requiredStaff: 3,
        status: CoverageStatus.understaffed,
      );

      final items = [fullyStaffed, understaffed];

      final allFiltered =
          service.filterCoverages(items, SiteCoverageFilter.all);
      expect(allFiltered.length, 2);

      final fullyFiltered =
          service.filterCoverages(items, SiteCoverageFilter.fullyStaffed);
      expect(fullyFiltered.length, 1);
      expect(fullyFiltered.first.siteId, 's1');

      final underFiltered =
          service.filterCoverages(items, SiteCoverageFilter.understaffed);
      expect(underFiltered.length, 1);
      expect(underFiltered.first.siteId, 's2');
    });
  });
}

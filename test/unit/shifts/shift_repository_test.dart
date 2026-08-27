import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/guards/domain/entities/guard.dart';
import 'package:cipher_x/features/guards/domain/repositories/guard_repository.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';
import 'package:cipher_x/features/sites/domain/repositories/site_repository.dart';
import 'package:cipher_x/features/shifts/data/datasources/firebase_shift_data_source.dart';
import 'package:cipher_x/features/shifts/data/repositories/shift_repository_impl.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift.dart';
import 'package:cipher_x/features/shifts/domain/failures/shift_failure.dart';

class FakeGuardRepository implements GuardRepository {
  final Map<String, Guard> guards = {};

  @override
  Future<Guard> createGuard(Guard guard) async {
    guards[guard.guardId] = guard;
    return guard;
  }

  @override
  Future<Guard?> getGuard({
    required String organizationId,
    required String guardId,
  }) async {
    final guard = guards[guardId];
    if (guard != null && guard.organizationId == organizationId) {
      return guard;
    }
    return null;
  }

  @override
  Future<List<Guard>> getGuards(String organizationId,
      {bool includeInactive = false}) async {
    return guards.values
        .where((g) => g.organizationId == organizationId)
        .toList();
  }

  @override
  Stream<List<Guard>> watchGuards(String organizationId,
      {bool includeInactive = false}) {
    return Stream.value(guards.values
        .where((g) => g.organizationId == organizationId)
        .toList());
  }

  @override
  Future<Guard> updateGuard(Guard guard) async {
    guards[guard.guardId] = guard;
    return guard;
  }

  @override
  Future<Guard> updateGuardStatus({
    required String organizationId,
    required String guardId,
    required GuardStatus status,
  }) async {
    final existing = guards[guardId];
    if (existing != null) {
      final updated = existing.copyWith(status: status);
      guards[guardId] = updated;
      return updated;
    }
    throw Exception('Guard not found');
  }

  @override
  Future<void> deleteGuard(
      {required String organizationId, required String guardId}) async {
    await updateGuardStatus(
        organizationId: organizationId,
        guardId: guardId,
        status: GuardStatus.inactive);
  }
}

class FakeSiteRepository implements SiteRepository {
  final Map<String, Site> sites = {};

  @override
  Future<Site> createSite(Site site) async {
    sites[site.siteId] = site;
    return site;
  }

  @override
  Future<Site?> getSite({
    required String organizationId,
    required String siteId,
  }) async {
    final site = sites[siteId];
    if (site != null && site.organizationId == organizationId) {
      return site;
    }
    return null;
  }

  @override
  Future<List<Site>> getSites(String organizationId,
      {bool includeInactive = false}) async {
    return sites.values
        .where((s) => s.organizationId == organizationId)
        .toList();
  }

  @override
  Stream<List<Site>> watchSites(String organizationId,
      {bool includeInactive = false}) {
    return Stream.value(
        sites.values.where((s) => s.organizationId == organizationId).toList());
  }

  @override
  Future<Site> updateSite(Site site) async {
    sites[site.siteId] = site;
    return site;
  }

  @override
  Future<Site> updateSiteStatus({
    required String organizationId,
    required String siteId,
    required SiteStatus status,
  }) async {
    final existing = sites[siteId];
    if (existing != null) {
      final updated = existing.copyWith(status: status);
      sites[siteId] = updated;
      return updated;
    }
    throw Exception('Site not found');
  }

  @override
  Future<void> deleteSite(
      {required String organizationId, required String siteId}) async {
    await updateSiteStatus(
        organizationId: organizationId,
        siteId: siteId,
        status: SiteStatus.inactive);
  }
}

class FakeShiftDataSource implements FirebaseShiftDataSource {
  final List<Shift> shifts = [];

  @override
  Future<Shift> createShift(Shift shift) async {
    final created = shift.id.isEmpty
        ? shift.copyWith(id: 'shift-${shifts.length + 1}')
        : shift;
    shifts.add(created);
    return created;
  }

  @override
  Future<Shift?> getShift(
      {required String organizationId, required String shiftId}) async {
    try {
      return shifts.firstWhere(
          (s) => s.id == shiftId && s.organizationId == organizationId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Shift>> getShifts(
    String organizationId, {
    String? siteId,
    String? guardId,
    String? shiftDate,
  }) async {
    return shifts.where((s) {
      if (s.organizationId != organizationId) return false;
      if (siteId != null && siteId.isNotEmpty && s.siteId != siteId) {
        return false;
      }
      if (guardId != null && guardId.isNotEmpty && s.guardId != guardId) {
        return false;
      }
      if (shiftDate != null &&
          shiftDate.isNotEmpty &&
          s.shiftDate != shiftDate) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Stream<List<Shift>> watchShifts(
    String organizationId, {
    String? siteId,
    String? guardId,
    String? shiftDate,
  }) {
    return Stream.value(
        shifts.where((s) => s.organizationId == organizationId).toList());
  }
}

void main() {
  group('ShiftRepositoryImpl Assignment Validation Integration Unit Tests', () {
    late FakeGuardRepository fakeGuardRepo;
    late FakeSiteRepository fakeSiteRepo;
    late FakeShiftDataSource fakeDataSource;
    late ShiftRepositoryImpl repository;

    const testGuard = Guard(
      guardId: 'g-101',
      organizationId: 'org-test',
      name: 'Rahul Sharma',
      employeeId: 'EMP-1001',
      phone: '+1 555-0199',
      status: GuardStatus.active,
    );

    const testSite = Site(
      siteId: 'site-001',
      organizationId: 'org-test',
      name: 'Cyber Gateway Tech Park',
      address: '123 Cyber Way',
      latitude: 17.44,
      longitude: 78.38,
      geofenceRadius: 50.0,
      status: SiteStatus.active,
    );

    final testShift = Shift(
      id: '',
      organizationId: 'org-test',
      siteId: 'site-001',
      siteName: 'Cyber Gateway Tech Park',
      guardId: 'g-101',
      guardName: 'Rahul Sharma',
      shiftDate: '2026-08-27',
      startTime: DateTime(2026, 8, 27, 9, 0),
      endTime: DateTime(2026, 8, 27, 17, 0),
      status: ShiftStatus.scheduled,
    );

    setUp(() {
      fakeGuardRepo = FakeGuardRepository();
      fakeSiteRepo = FakeSiteRepository();
      fakeDataSource = FakeShiftDataSource();
      repository = ShiftRepositoryImpl(
        dataSource: fakeDataSource,
        guardRepository: fakeGuardRepo,
        siteRepository: fakeSiteRepo,
      );

      fakeGuardRepo.guards[testGuard.guardId] = testGuard;
      fakeSiteRepo.sites[testSite.siteId] = testSite;
    });

    test('Succeeds creating valid shift', () async {
      final created = await repository.createShift(testShift);
      expect(created.id, isNotEmpty);
      expect(fakeDataSource.shifts.length, equals(1));
    });

    test('Rejects creating shift when guard is inactive', () async {
      fakeGuardRepo.guards[testGuard.guardId] =
          testGuard.copyWith(status: GuardStatus.inactive);

      expect(
        () => repository.createShift(testShift),
        throwsA(isA<GuardInactiveFailure>()),
      );
      expect(fakeDataSource.shifts, isEmpty);
    });

    test('Rejects creating shift when site is inactive', () async {
      fakeSiteRepo.sites[testSite.siteId] =
          testSite.copyWith(status: SiteStatus.inactive);

      expect(
        () => repository.createShift(testShift),
        throwsA(isA<SiteInactiveFailure>()),
      );
      expect(fakeDataSource.shifts, isEmpty);
    });

    test('Rejects creating shift when guard has an overlapping shift',
        () async {
      await repository.createShift(testShift);

      final overlappingShift = testShift.copyWith(
        startTime: DateTime(2026, 8, 27, 13, 0),
        endTime: DateTime(2026, 8, 27, 18, 0),
      );

      expect(
        () => repository.createShift(overlappingShift),
        throwsA(isA<ShiftConflictFailure>()),
      );
      expect(fakeDataSource.shifts.length, equals(1));
    });
  });
}

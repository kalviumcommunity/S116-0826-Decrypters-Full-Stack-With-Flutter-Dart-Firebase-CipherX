import '../../../guards/domain/repositories/guard_repository.dart';
import '../../../sites/domain/repositories/site_repository.dart';
import '../../domain/entities/shift.dart';
import '../../domain/repositories/shift_repository.dart';
import '../../domain/validators/shift_assignment_validator.dart';
import '../datasources/firebase_shift_data_source.dart';

class ShiftRepositoryImpl implements ShiftRepository {
  final FirebaseShiftDataSource _dataSource;
  final GuardRepository? _guardRepository;
  final SiteRepository? _siteRepository;

  ShiftRepositoryImpl({
    required FirebaseShiftDataSource dataSource,
    GuardRepository? guardRepository,
    SiteRepository? siteRepository,
  })  : _dataSource = dataSource,
        _guardRepository = guardRepository,
        _siteRepository = siteRepository;

  @override
  Future<Shift> createShift(Shift shift) async {
    if (_guardRepository != null && _siteRepository != null) {
      final guard = await _guardRepository.getGuard(
        organizationId: shift.organizationId,
        guardId: shift.guardId,
      );
      final site = await _siteRepository.getSite(
        organizationId: shift.organizationId,
        siteId: shift.siteId,
      );

      final existingShifts = await _dataSource.getShifts(
        shift.organizationId,
        guardId: shift.guardId,
        shiftDate: shift.shiftDate,
      );

      ShiftAssignmentValidator.validateAssignment(
        shift: shift,
        guard: guard,
        site: site,
        existingShifts: existingShifts,
      );
    }

    return await _dataSource.createShift(shift);
  }

  @override
  Future<Shift?> getShift({
    required String organizationId,
    required String shiftId,
  }) {
    return _dataSource.getShift(
      organizationId: organizationId,
      shiftId: shiftId,
    );
  }

  @override
  Future<List<Shift>> getShifts(
    String organizationId, {
    String? siteId,
    String? guardId,
    String? shiftDate,
  }) {
    return _dataSource.getShifts(
      organizationId,
      siteId: siteId,
      guardId: guardId,
      shiftDate: shiftDate,
    );
  }

  @override
  Stream<List<Shift>> watchShifts(
    String organizationId, {
    String? siteId,
    String? guardId,
    String? shiftDate,
  }) {
    return _dataSource.watchShifts(
      organizationId,
      siteId: siteId,
      guardId: guardId,
      shiftDate: shiftDate,
    );
  }
}

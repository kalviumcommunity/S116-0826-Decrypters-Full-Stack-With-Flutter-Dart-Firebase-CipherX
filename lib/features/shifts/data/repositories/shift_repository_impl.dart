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

      final existingShifts = await _dataSource.getShiftsByGuard(
        shift.organizationId,
        shift.guardId,
        date: shift.date,
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
  Future<List<Shift>> getShiftsByOrganization(
    String organizationId, {
    DateTime? date,
    ShiftStatus? status,
  }) {
    return _dataSource.getShiftsByOrganization(
      organizationId,
      date: date,
      status: status,
    );
  }

  @override
  Future<List<Shift>> getShiftsByGuard(
    String organizationId,
    String guardId, {
    DateTime? date,
  }) {
    return _dataSource.getShiftsByGuard(
      organizationId,
      guardId,
      date: date,
    );
  }

  @override
  Future<List<Shift>> getShiftsBySite(
    String organizationId,
    String siteId, {
    DateTime? date,
  }) {
    return _dataSource.getShiftsBySite(
      organizationId,
      siteId,
      date: date,
    );
  }

  @override
  Future<Shift> updateShift(Shift shift) async {
    if (_guardRepository != null && _siteRepository != null) {
      final guard = await _guardRepository.getGuard(
        organizationId: shift.organizationId,
        guardId: shift.guardId,
      );
      final site = await _siteRepository.getSite(
        organizationId: shift.organizationId,
        siteId: shift.siteId,
      );

      final existingShifts = await _dataSource.getShiftsByGuard(
        shift.organizationId,
        shift.guardId,
        date: shift.date,
      );

      ShiftAssignmentValidator.validateAssignment(
        shift: shift,
        guard: guard,
        site: site,
        existingShifts: existingShifts,
      );
    }
    return await _dataSource.updateShift(shift);
  }

  @override
  Future<Shift> updateShiftStatus({
    required String organizationId,
    required String shiftId,
    required ShiftStatus status,
  }) {
    return _dataSource.updateShiftStatus(
      organizationId: organizationId,
      shiftId: shiftId,
      status: status,
    );
  }

  @override
  Future<void> cancelShift({
    required String organizationId,
    required String shiftId,
  }) async {
    await updateShiftStatus(
      organizationId: organizationId,
      shiftId: shiftId,
      status: ShiftStatus.cancelled,
    );
  }
}

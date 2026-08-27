import '../../domain/entities/shift.dart';
import '../../domain/repositories/shift_repository.dart';
import '../datasources/firebase_shift_data_source.dart';

class ShiftRepositoryImpl implements ShiftRepository {
  final FirebaseShiftDataSource _dataSource;

  ShiftRepositoryImpl({required FirebaseShiftDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<Shift> createShift(Shift shift) {
    return _dataSource.createShift(shift);
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
  Future<List<Shift>> getShiftsByOrganization(String organizationId) {
    return _dataSource.getShiftsByOrganization(organizationId);
  }

  @override
  Future<List<Shift>> getShiftsByGuard(
    String organizationId,
    String guardId,
  ) {
    return _dataSource.getShiftsByGuard(organizationId, guardId);
  }

  @override
  Stream<List<Shift>> watchShiftsByGuard(
    String organizationId,
    String guardId,
  ) {
    return _dataSource.watchShiftsByGuard(organizationId, guardId);
  }

  @override
  Future<List<Shift>> getShiftsBySite(
    String organizationId,
    String siteId,
  ) {
    return _dataSource.getShiftsBySite(organizationId, siteId);
  }

  @override
  Future<Shift> updateShift(Shift shift) {
    return _dataSource.updateShift(shift);
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
  }) {
    return _dataSource.cancelShift(
      organizationId: organizationId,
      shiftId: shiftId,
    );
  }
}

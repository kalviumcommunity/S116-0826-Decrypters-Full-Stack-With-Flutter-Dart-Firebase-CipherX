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

import '../../domain/entities/shift.dart';
import '../../domain/repositories/shift_repository.dart';
import '../datasources/firebase_shift_data_source.dart';

class ShiftRepositoryImpl implements ShiftRepository {
  final FirebaseShiftDataSource _dataSource;

  ShiftRepositoryImpl(this._dataSource);

  @override
  Future<List<Shift>> getShiftsByGuard(String organizationId, String guardId) {
    return _dataSource.getShiftsByGuard(organizationId, guardId);
  }

  @override
  Future<Shift?> getShiftById(String organizationId, String shiftId) {
    return _dataSource.getShiftById(organizationId, shiftId);
  }
}

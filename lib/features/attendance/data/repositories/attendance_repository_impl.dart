import '../../../location/domain/entities/location_data.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/failures/attendance_failure.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/firebase_attendance_data_source.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final FirebaseAttendanceDataSource? _dataSource;

  AttendanceRepositoryImpl({
    FirebaseAttendanceDataSource? dataSource,
  }) : _dataSource = dataSource;

  FirebaseAttendanceDataSource get dataSource =>
      _dataSource ?? FirebaseAttendanceDataSource();

  @override
  Future<AttendanceRecord> createAttendanceRecord(
    AttendanceRecord record,
  ) async {
    try {
      if (record.organizationId.trim().isEmpty) {
        throw const UnknownAttendanceFailure(
            'Organization ID cannot be empty.');
      }
      return await dataSource.createAttendanceRecord(record);
    } catch (e) {
      if (e is AttendanceFailure) rethrow;
      throw UnknownAttendanceFailure(e.toString());
    }
  }

  @override
  Future<AttendanceRecord?> getActiveAttendanceForGuard({
    required String organizationId,
    required String guardId,
  }) async {
    try {
      if (organizationId.trim().isEmpty || guardId.trim().isEmpty) {
        return null;
      }
      return await dataSource.getActiveAttendanceForGuard(
        organizationId: organizationId,
        guardId: guardId,
      );
    } catch (e) {
      if (e is AttendanceFailure) rethrow;
      throw UnknownAttendanceFailure(e.toString());
    }
  }

  @override
  Stream<AttendanceRecord?> watchActiveAttendanceForGuard({
    required String organizationId,
    required String guardId,
  }) {
    if (organizationId.trim().isEmpty || guardId.trim().isEmpty) {
      return Stream.value(null);
    }
    return dataSource.watchActiveAttendanceForGuard(
      organizationId: organizationId,
      guardId: guardId,
    );
  }

  @override
  Future<AttendanceRecord?> getAttendanceById({
    required String organizationId,
    required String attendanceId,
  }) async {
    try {
      if (organizationId.trim().isEmpty || attendanceId.trim().isEmpty) {
        return null;
      }
      return await dataSource.getAttendanceById(
        organizationId: organizationId,
        attendanceId: attendanceId,
      );
    } catch (e) {
      if (e is AttendanceFailure) rethrow;
      throw UnknownAttendanceFailure(e.toString());
    }
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceHistoryForGuard({
    required String organizationId,
    required String guardId,
  }) async {
    try {
      if (organizationId.trim().isEmpty || guardId.trim().isEmpty) {
        return [];
      }
      return await dataSource.getAttendanceHistoryForGuard(
        organizationId: organizationId,
        guardId: guardId,
      );
    } catch (e) {
      if (e is AttendanceFailure) rethrow;
      throw UnknownAttendanceFailure(e.toString());
    }
  }

  @override
  Stream<List<AttendanceRecord>> watchAttendanceHistoryForGuard({
    required String organizationId,
    required String guardId,
  }) {
    if (organizationId.trim().isEmpty || guardId.trim().isEmpty) {
      return Stream.value([]);
    }
    return dataSource.watchAttendanceHistoryForGuard(
      organizationId: organizationId,
      guardId: guardId,
    );
  }

  @override
  Future<AttendanceRecord> checkOutGuard({
    required String organizationId,
    required String attendanceId,
    required LocationData location,
  }) async {
    try {
      if (organizationId.trim().isEmpty || attendanceId.trim().isEmpty) {
        throw const UnknownAttendanceFailure(
          'Organization ID and Attendance ID are required.',
        );
      }
      return await dataSource.checkOutGuard(
        organizationId: organizationId,
        attendanceId: attendanceId,
        location: location,
      );
    } catch (e) {
      if (e is AttendanceFailure) rethrow;
      throw UnknownAttendanceFailure(e.toString());
    }
  }
}

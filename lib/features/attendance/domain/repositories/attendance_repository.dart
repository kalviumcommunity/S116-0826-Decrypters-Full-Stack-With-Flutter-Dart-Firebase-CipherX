import '../../../location/domain/entities/location_data.dart';
import '../entities/attendance_record.dart';

abstract class AttendanceRepository {
  Future<AttendanceRecord> createAttendanceRecord(AttendanceRecord record);

  Future<AttendanceRecord?> getActiveAttendanceForGuard({
    required String organizationId,
    required String guardId,
  });

  Stream<AttendanceRecord?> watchActiveAttendanceForGuard({
    required String organizationId,
    required String guardId,
  });

  Future<AttendanceRecord?> getAttendanceById({
    required String organizationId,
    required String attendanceId,
  });

  Future<List<AttendanceRecord>> getAttendanceHistoryForGuard({
    required String organizationId,
    required String guardId,
  });

  Stream<List<AttendanceRecord>> watchAttendanceHistoryForGuard({
    required String organizationId,
    required String guardId,
  });

  Future<AttendanceRecord> checkOutGuard({
    required String organizationId,
    required String attendanceId,
    required LocationData location,
  });
}

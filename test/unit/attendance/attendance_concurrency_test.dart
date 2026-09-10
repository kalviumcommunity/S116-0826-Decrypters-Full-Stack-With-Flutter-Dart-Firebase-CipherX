import 'package:cipher_x/features/attendance/data/datasources/firebase_attendance_data_source.dart';
import 'package:cipher_x/features/attendance/domain/entities/attendance_record.dart';
import 'package:cipher_x/features/attendance/domain/failures/check_in_failure.dart';
import 'package:cipher_x/features/location/domain/entities/location_data.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseAttendanceDataSource dataSource;

  final testLocation = LocationData(
    latitude: 18.5204,
    longitude: 73.8567,
    accuracy: 5.0,
    timestamp: DateTime.utc(2026, 9, 10, 9, 0),
  );

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FirebaseAttendanceDataSource(firestore: fakeFirestore);
  });

  group('Atomic Check-In & Concurrency Protection Tests', () {
    test('deterministic document ID att_\${shiftId} is used upon check-in',
        () async {
      final record = AttendanceRecord(
        attendanceId: '',
        organizationId: 'org_test',
        shiftId: 'shift_alpha_100',
        siteId: 'site_100',
        guardId: 'guard_100',
        checkInTime: DateTime.utc(2026, 9, 10, 9, 0),
        checkInLocation: testLocation,
      );

      final result = await dataSource.checkInGuard(record: record);

      expect(result.attendanceId, equals('att_shift_alpha_100'));

      final doc = await fakeFirestore
          .collection('organizations')
          .doc('org_test')
          .collection('attendance')
          .doc('att_shift_alpha_100')
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['shiftId'], equals('shift_alpha_100'));
      expect(doc.data()!['guardId'], equals('guard_100'));
      expect(doc.data()!['siteId'], equals('site_100'));
      expect(doc.data()!['status'], equals('active'));
    });

    test(
        'second check-in attempt for the same shift throws AlreadyCheckedInFailure',
        () async {
      final record = AttendanceRecord(
        attendanceId: '',
        organizationId: 'org_test',
        shiftId: 'shift_001',
        siteId: 'site_001',
        guardId: 'guard_123',
        checkInTime: DateTime.utc(2026, 9, 10, 9, 0),
        checkInLocation: testLocation,
      );

      // First check-in succeeds
      final first = await dataSource.checkInGuard(record: record);
      expect(first.attendanceId, equals('att_shift_001'));

      // Duplicate check-in fails atomically
      expect(
        () => dataSource.checkInGuard(record: record),
        throwsA(isA<AlreadyCheckedInFailure>()),
      );
    });

    test(
        'simultaneous concurrent check-ins enforce exactly ONE SHIFT -> ONE CHECK-IN',
        () async {
      final record = AttendanceRecord(
        attendanceId: '',
        organizationId: 'org_test',
        shiftId: 'shift_race_001',
        siteId: 'site_race_001',
        guardId: 'guard_race_001',
        checkInTime: DateTime.utc(2026, 9, 10, 9, 0),
        checkInLocation: testLocation,
      );

      int successCount = 0;
      int duplicateFailureCount = 0;

      // Simulate 5 simultaneous check-in attempts on the same shift
      final futures = List.generate(5, (_) async {
        try {
          await dataSource.checkInGuard(record: record);
          successCount++;
        } on AlreadyCheckedInFailure {
          duplicateFailureCount++;
        } catch (_) {}
      });

      await Future.wait(futures);

      // Invariant: Exactly one succeeded, others were rejected as duplicates!
      expect(successCount, equals(1));
      expect(duplicateFailureCount, equals(4));

      // Verify that Firestore collection contains exactly one record
      final snapshot = await fakeFirestore
          .collection('organizations')
          .doc('org_test')
          .collection('attendance')
          .get();

      expect(snapshot.docs.length, equals(1));
      expect(snapshot.docs.first.id, equals('att_shift_race_001'));
    });

    test('different shifts can be checked into independently', () async {
      final record1 = AttendanceRecord(
        attendanceId: '',
        organizationId: 'org_test',
        shiftId: 'shift_001',
        siteId: 'site_001',
        guardId: 'guard_123',
        checkInTime: DateTime.utc(2026, 9, 10, 9, 0),
        checkInLocation: testLocation,
      );

      final record2 = AttendanceRecord(
        attendanceId: '',
        organizationId: 'org_test',
        shiftId: 'shift_002',
        siteId: 'site_002',
        guardId: 'guard_123',
        checkInTime: DateTime.utc(2026, 9, 10, 18, 0),
        checkInLocation: testLocation,
      );

      final result1 = await dataSource.checkInGuard(record: record1);
      final result2 = await dataSource.checkInGuard(record: record2);

      expect(result1.attendanceId, equals('att_shift_001'));
      expect(result2.attendanceId, equals('att_shift_002'));

      final snapshot = await fakeFirestore
          .collection('organizations')
          .doc('org_test')
          .collection('attendance')
          .get();

      expect(snapshot.docs.length, equals(2));
    });
  });
}

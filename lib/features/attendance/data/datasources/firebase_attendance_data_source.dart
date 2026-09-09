import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../location/domain/entities/location_data.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/failures/attendance_failure.dart';
import '../../domain/failures/check_in_failure.dart';

class FirebaseAttendanceDataSource {
  final FirebaseFirestore? _firestore;

  FirebaseAttendanceDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore get db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _attendanceCollection(
    String organizationId,
  ) {
    return db
        .collection('organizations')
        .doc(organizationId)
        .collection('attendance');
  }

  Future<AttendanceRecord> createAttendanceRecord(
    AttendanceRecord record,
  ) async {
    final collection = _attendanceCollection(record.organizationId);
    final docRef = record.attendanceId.trim().isNotEmpty
        ? collection.doc(record.attendanceId.trim())
        : collection.doc();

    final assignedId = docRef.id;
    final now = DateTime.now();
    final prepared = record.copyWith(
      attendanceId: assignedId,
      createdAt: record.createdAt ?? now,
      updatedAt: record.updatedAt ?? now,
    );

    final mapData = prepared.toMap();
    mapData['createdAt'] = FieldValue.serverTimestamp();
    mapData['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.set(mapData);

    final doc = await docRef.get();
    if (doc.exists && doc.data() != null) {
      return AttendanceRecord.fromMap(doc.data()!, doc.id);
    }
    return prepared;
  }

  /// Atomically creates an attendance check-in record using a deterministic document ID.
  ///
  /// Enforces single-attendance per shift at the database transaction layer.
  Future<AttendanceRecord> checkInGuard({
    required AttendanceRecord record,
  }) async {
    final deterministicId = record.attendanceId.trim().isNotEmpty
        ? record.attendanceId.trim()
        : 'att_${record.shiftId}';

    final docRef =
        _attendanceCollection(record.organizationId).doc(deterministicId);

    return await db.runTransaction<AttendanceRecord>((transaction) async {
      final doc = await transaction.get(docRef);

      if (doc.exists && doc.data() != null) {
        throw const AlreadyCheckedInFailure();
      }

      final now = DateTime.now();
      final prepared = record.copyWith(
        attendanceId: deterministicId,
        createdAt: record.createdAt ?? now,
        updatedAt: record.updatedAt ?? now,
      );

      final mapData = prepared.toMap();
      mapData['checkInTime'] = FieldValue.serverTimestamp();
      mapData['createdAt'] = FieldValue.serverTimestamp();
      mapData['updatedAt'] = FieldValue.serverTimestamp();

      transaction.set(docRef, mapData);

      return prepared;
    });
  }

  Future<AttendanceRecord?> getActiveAttendanceForGuard({
    required String organizationId,
    required String guardId,
  }) async {
    final snapshot = await _attendanceCollection(organizationId)
        .where('guardId', isEqualTo: guardId)
        .where('status', isEqualTo: AttendanceStatus.active.toMapString())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return AttendanceRecord.fromMap(
      snapshot.docs.first.data(),
      snapshot.docs.first.id,
    );
  }

  Stream<AttendanceRecord?> watchActiveAttendanceForGuard({
    required String organizationId,
    required String guardId,
  }) {
    return _attendanceCollection(organizationId)
        .where('guardId', isEqualTo: guardId)
        .where('status', isEqualTo: AttendanceStatus.active.toMapString())
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return AttendanceRecord.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    });
  }

  Future<AttendanceRecord?> getAttendanceById({
    required String organizationId,
    required String attendanceId,
  }) async {
    final doc =
        await _attendanceCollection(organizationId).doc(attendanceId).get();
    if (!doc.exists || doc.data() == null) return null;
    return AttendanceRecord.fromMap(doc.data()!, doc.id);
  }

  Future<List<AttendanceRecord>> getAttendanceHistoryForGuard({
    required String organizationId,
    required String guardId,
  }) async {
    final snapshot = await _attendanceCollection(organizationId)
        .where('guardId', isEqualTo: guardId)
        .get();

    final records = snapshot.docs
        .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
        .toList();

    records.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
    return records;
  }

  Stream<List<AttendanceRecord>> watchAttendanceHistoryForGuard({
    required String organizationId,
    required String guardId,
  }) {
    return _attendanceCollection(organizationId)
        .where('guardId', isEqualTo: guardId)
        .snapshots()
        .map((snapshot) {
      final records = snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
          .toList();
      records.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
      return records;
    });
  }

  Future<AttendanceRecord> checkOutGuard({
    required String organizationId,
    required String attendanceId,
    required LocationData location,
  }) async {
    final docRef = _attendanceCollection(organizationId).doc(attendanceId);

    return await db.runTransaction<AttendanceRecord>((transaction) async {
      final doc = await transaction.get(docRef);

      if (!doc.exists || doc.data() == null) {
        throw const AttendanceNotFoundFailure();
      }

      final existing = AttendanceRecord.fromMap(doc.data()!, doc.id);
      if (existing.isCheckedOut) {
        throw const DuplicateCheckOutFailure();
      }

      final now = DateTime.now();
      transaction.update(docRef, {
        'checkOutTime': FieldValue.serverTimestamp(),
        'checkOutLocation': location.toMap(),
        'status': AttendanceStatus.completed.toMapString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return existing.checkOut(
        location: location,
        timestamp: now,
      );
    });
  }
}

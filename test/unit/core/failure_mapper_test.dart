import 'dart:io';
import 'package:cipher_x/core/errors/app_exception.dart';
import 'package:cipher_x/core/errors/failure_mapper.dart';
import 'package:cipher_x/features/attendance/domain/failures/attendance_failure.dart';
import 'package:cipher_x/features/incidents/domain/failures/incident_failure.dart';
import 'package:cipher_x/features/location/domain/failures/location_failure.dart';
import 'package:cipher_x/features/shifts/domain/failures/shift_failure.dart'
    hide SiteNotFoundFailure;
import 'package:cipher_x/features/sites/domain/failures/site_failure.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FailureMapper Unit Tests', () {
    test('maps null to default message', () {
      expect(FailureMapper.mapToMessage(null), contains('unexpected error'));
    });

    test(
        'maps NetworkException and SocketException to network connection message',
        () {
      const netEx = NetworkException('Connection failed');
      expect(FailureMapper.mapToMessage(netEx),
          contains('Network connection unavailable'));

      const socketEx = SocketException('Failed host lookup');
      expect(FailureMapper.mapToMessage(socketEx),
          contains('Network connection unavailable'));
    });

    test('maps FirebaseException network failure and permission denied', () {
      final netFbEx = FirebaseException(
          plugin: 'firestore', code: 'network-request-failed');
      expect(FailureMapper.mapToMessage(netFbEx),
          contains('Network connection lost'));

      final permFbEx =
          FirebaseException(plugin: 'firestore', code: 'permission-denied');
      expect(FailureMapper.mapToMessage(permFbEx),
          contains('do not have permission'));
    });

    test('maps domain failures cleanly', () {
      const locFailure = LocationPermissionDeniedFailure();
      expect(
          FailureMapper.mapToMessage(locFailure), equals(locFailure.message));

      const siteFailure = SiteNotFoundFailure();
      expect(
          FailureMapper.mapToMessage(siteFailure), equals(siteFailure.message));

      const incidentFailure = InvalidIncidentDataFailure();
      expect(FailureMapper.mapToMessage(incidentFailure),
          equals(incidentFailure.message));

      const shiftFailure = ExpiredShiftFailure();
      expect(FailureMapper.mapToMessage(shiftFailure),
          equals(shiftFailure.message));

      const attendanceFailure = AttendanceNotFoundFailure();
      expect(FailureMapper.mapToMessage(attendanceFailure),
          equals(attendanceFailure.message));
    });

    test('maps string error patterns for QR, Location, Shift and Permissions',
        () {
      expect(
        FailureMapper.mapToMessage('Invalid QR code format'),
        contains('Invalid QR code'),
      );
      expect(
        FailureMapper.mapToMessage('User is outside permitted geofence'),
        contains('outside the permitted site area'),
      );
      expect(
        FailureMapper.mapToMessage('Shift expired 30 minutes ago'),
        contains('expired or is no longer active'),
      );
      expect(
        FailureMapper.mapToMessage('Camera permission denied'),
        contains('Camera permission is required'),
      );
    });
  });
}

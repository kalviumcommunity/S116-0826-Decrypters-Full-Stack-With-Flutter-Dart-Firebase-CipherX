import 'dart:async';
import 'dart:io';
import 'package:cipher_x/core/errors/app_exception.dart';
import 'package:cipher_x/core/errors/failure_mapper.dart';
import 'package:cipher_x/features/attendance/domain/failures/attendance_failure.dart';
import 'package:cipher_x/features/guards/domain/failures/guard_failure.dart'
    as guard_f;
import 'package:cipher_x/features/incidents/domain/failures/incident_failure.dart';
import 'package:cipher_x/features/location/domain/failures/location_failure.dart';
import 'package:cipher_x/features/shifts/domain/failures/shift_failure.dart'
    as shift_f;
import 'package:cipher_x/features/sites/domain/failures/site_failure.dart'
    as site_f;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FailureMapper Unit Tests', () {
    test('maps null to default unexpected error message', () {
      expect(FailureMapper.mapToMessage(null), 'An unexpected error occurred.');
    });

    group('Domain Failures Mapping', () {
      test('maps AttendanceFailure instances', () {
        const failure1 = AttendanceNotFoundFailure();
        expect(FailureMapper.mapToMessage(failure1), failure1.message);

        const failure2 = DuplicateCheckOutFailure();
        expect(FailureMapper.mapToMessage(failure2), failure2.message);
      });

      test('maps LocationFailure instances', () {
        const failure1 = LocationPermissionDeniedFailure();
        expect(FailureMapper.mapToMessage(failure1), failure1.message);

        const failure2 = LocationServiceDisabledFailure();
        expect(FailureMapper.mapToMessage(failure2), failure2.message);
      });

      test('maps SiteFailure instances', () {
        const failure1 = site_f.SiteNotFoundFailure();
        expect(FailureMapper.mapToMessage(failure1), failure1.message);

        const failure2 = site_f.SiteValidationFailure('Site name is invalid.');
        expect(FailureMapper.mapToMessage(failure2), 'Site name is invalid.');
      });

      test('maps GuardFailure instances', () {
        const failure1 = guard_f.GuardNotFoundFailure();
        expect(FailureMapper.mapToMessage(failure1), failure1.message);

        const failure2 = guard_f.GuardValidationFailure('Employee ID exists.');
        expect(FailureMapper.mapToMessage(failure2), 'Employee ID exists.');
      });

      test('maps IncidentFailure instances', () {
        const failure1 = IncidentNotFoundFailure();
        expect(FailureMapper.mapToMessage(failure1), failure1.message);

        const failure2 = InvalidIncidentIdFailure();
        expect(FailureMapper.mapToMessage(failure2), failure2.message);
      });

      test('maps ShiftFailure instances', () {
        const failure1 = shift_f.ShiftNotFoundFailure();
        expect(FailureMapper.mapToMessage(failure1), failure1.message);

        const failure2 = shift_f.ExpiredShiftFailure();
        expect(FailureMapper.mapToMessage(failure2), failure2.message);
      });
    });

    group('AppException Mapping', () {
      test('maps NetworkException to user-friendly message', () {
        const ex = NetworkException('Connection dropped');
        expect(FailureMapper.mapToMessage(ex),
            contains('Network connection unavailable'));
      });

      test('maps ValidationException to user-friendly message', () {
        const ex1 = ValidationException('Field required');
        expect(FailureMapper.mapToMessage(ex1), 'Field required');

        const ex2 = ValidationException('');
        expect(FailureMapper.mapToMessage(ex2),
            contains('Invalid data submitted'));
      });

      test('maps SecurityException to user-friendly message', () {
        const ex1 = SecurityException('Forbidden action');
        expect(FailureMapper.mapToMessage(ex1), 'Forbidden action');

        const ex2 = SecurityException('');
        expect(FailureMapper.mapToMessage(ex2), contains('Access denied'));
      });
    });

    group('I/O & Network Exceptions', () {
      test('maps SocketException to connection message', () {
        const ex = SocketException('Failed host lookup');
        expect(FailureMapper.mapToMessage(ex),
            contains('Network connection unavailable'));
      });

      test('maps TimeoutException to timeout message', () {
        final ex = TimeoutException('Took too long');
        expect(FailureMapper.mapToMessage(ex), contains('operation timed out'));
      });
    });

    group('FirebaseException Mapping', () {
      test('maps common Firebase error codes', () {
        final netEx = FirebaseException(
            plugin: 'firestore', code: 'network-request-failed');
        expect(FailureMapper.mapToMessage(netEx),
            contains('Network connection lost'));

        final unavailEx =
            FirebaseException(plugin: 'firestore', code: 'unavailable');
        expect(FailureMapper.mapToMessage(unavailEx),
            contains('Network connection lost'));

        final permEx =
            FirebaseException(plugin: 'firestore', code: 'permission-denied');
        expect(FailureMapper.mapToMessage(permEx),
            contains('permission to perform this action'));

        final notFoundEx =
            FirebaseException(plugin: 'firestore', code: 'not-found');
        expect(FailureMapper.mapToMessage(notFoundEx),
            contains('record or resource was not found'));

        final existsEx =
            FirebaseException(plugin: 'firestore', code: 'already-exists');
        expect(
            FailureMapper.mapToMessage(existsEx), contains('already exists'));

        final quotaEx =
            FirebaseException(plugin: 'firestore', code: 'resource-exhausted');
        expect(FailureMapper.mapToMessage(quotaEx),
            contains('Request limit exceeded'));

        final authEx =
            FirebaseException(plugin: 'firestore', code: 'unauthenticated');
        expect(FailureMapper.mapToMessage(authEx),
            contains('session has expired'));

        final timeoutEx =
            FirebaseException(plugin: 'firestore', code: 'deadline-exceeded');
        expect(FailureMapper.mapToMessage(timeoutEx), contains('timed out'));

        final unknownWithMsg = FirebaseException(
            plugin: 'firestore',
            code: 'unknown',
            message: 'Custom Firestore message');
        expect(FailureMapper.mapToMessage(unknownWithMsg),
            'Custom Firestore message');
      });
    });

    group('String Error Patterns & Exception Fallbacks', () {
      test('maps string permission patterns', () {
        expect(FailureMapper.mapToMessage('Camera permission not granted'),
            contains('Camera permission is required'));
        expect(FailureMapper.mapToMessage('Location permission is denied'),
            contains('Location permission is required'));
      });

      test('maps string location & geofence patterns', () {
        expect(
            FailureMapper.mapToMessage('Guard is outside permitted boundary'),
            contains('outside the permitted site area'));
        expect(FailureMapper.mapToMessage('Device GPS disabled'),
            contains('Location services (GPS) are disabled'));
      });

      test('maps string QR patterns', () {
        expect(FailureMapper.mapToMessage('Invalid QR format'),
            contains('Invalid QR code'));
        expect(FailureMapper.mapToMessage('Wrong site QR scanned'),
            contains('belongs to a different site'));
      });

      test('maps string shift expiration patterns', () {
        expect(FailureMapper.mapToMessage('Expired shift scan'),
            contains('shift has expired'));
      });

      test('cleans raw Exception prefix', () {
        expect(FailureMapper.mapToMessage('Exception: Custom user error'),
            'Custom user error');
        expect(FailureMapper.mapToMessage('Plain string error'),
            'Plain string error');
      });
    });
  });
}

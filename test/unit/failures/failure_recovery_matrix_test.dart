import 'dart:async';
import 'dart:io';
import 'package:cipher_x/core/errors/app_exception.dart';
import 'package:cipher_x/core/errors/failure_mapper.dart';
import 'package:cipher_x/features/attendance/domain/failures/check_in_failure.dart';
import 'package:cipher_x/features/location/domain/failures/location_failure.dart';
import 'package:cipher_x/features/shifts/domain/failures/shift_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QA Hardening: Network, GPS, and QR Failure Recovery Matrix Tests', () {
    test('1. GPS Failure Scenarios map to clear, actionable messages', () {
      const disabledGps = LocationDisabledFailure();
      const permDenied = LocationPermissionDeniedFailure();
      const poorAcc = PoorGpsAccuracyFailure();
      const outOfBounds = OutsideGeofenceFailure();

      expect(FailureMapper.mapToMessage(disabledGps), contains('Location services (GPS) are disabled'));
      expect(FailureMapper.mapToMessage(permDenied), contains('Location permission is required'));
      expect(FailureMapper.mapToMessage(poorAcc), contains('GPS accuracy is insufficient'));
      expect(FailureMapper.mapToMessage(outOfBounds), contains('outside the permitted site area'));
    });

    test('2. QR Failure Scenarios guide guard without crashing', () {
      const invalidQr = QrValidationFailedFailure();
      const siteMismatch = QrSiteMismatchFailure();

      expect(FailureMapper.mapToMessage(invalidQr), contains('Invalid QR code'));
      expect(FailureMapper.mapToMessage(siteMismatch), contains('belongs to a different site'));
    });

    test('3. Network Outage & Timeout Scenarios fail gracefully', () {
      final socketErr = const SocketException('Failed host lookup: firestore.googleapis.com');
      final timeoutErr = TimeoutException('Operation took longer than 15000ms');
      final networkAppEx = NetworkException('Cannot connect to Cipher-X server');

      expect(FailureMapper.mapToMessage(socketErr), contains('Network connection unavailable'));
      expect(FailureMapper.mapToMessage(timeoutErr), contains('operation timed out'));
      expect(FailureMapper.mapToMessage(networkAppEx), contains('Network connection unavailable'));
    });

    test('4. Security and RBAC Violations provide clean non-technical feedback', () {
      const unauthRole = UnauthorizedRoleFailure();
      const orgMismatch = GuardOrgMismatchFailure();
      const guardMismatch = ShiftGuardMismatchFailure();

      expect(FailureMapper.mapToMessage(unauthRole), isNotEmpty);
      expect(FailureMapper.mapToMessage(orgMismatch), contains('Tenant isolation'));
      expect(FailureMapper.mapToMessage(guardMismatch), contains('Security violation'));
    });

    test('5. Null or undefined errors provide safe fallback message', () {
      expect(FailureMapper.mapToMessage(null), equals('An unexpected error occurred.'));
      expect(FailureMapper.mapToMessage(''), isNotEmpty);
    });
  });
}

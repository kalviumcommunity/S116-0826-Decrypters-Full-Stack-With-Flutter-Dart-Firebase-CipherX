import 'package:cipher_x/features/location/domain/entities/location_data.dart';
import 'package:cipher_x/features/location/domain/entities/location_permission_state.dart';
import 'package:cipher_x/features/location/domain/failures/location_failure.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_location_service.dart';

void main() {
  group('LocationService Domain Contract Tests', () {
    late FakeLocationService service;

    setUp(() {
      service = FakeLocationService();
    });

    test('checkPermission returns current permission state', () async {
      final state = await service.checkPermission();
      expect(state, equals(LocationPermissionState.granted));
    });

    test('requestPermission transitions denied to granted in fake service',
        () async {
      service.permissionState = LocationPermissionState.denied;
      final state = await service.requestPermission();
      expect(state, equals(LocationPermissionState.granted));
    });

    test('isLocationServiceEnabled reports correct boolean status', () async {
      expect(await service.isLocationServiceEnabled(), isTrue);
      service.isServiceEnabled = false;
      expect(await service.isLocationServiceEnabled(), isFalse);
    });

    test(
        'getCurrentLocation returns LocationData when service & permissions are valid',
        () async {
      final expected = LocationData(
        latitude: 19.0760,
        longitude: 72.8777,
        accuracy: 8.0,
        timestamp: DateTime.utc(2026, 8, 28, 12, 0),
      );
      service.currentLocationData = expected;

      final result = await service.getCurrentLocation();
      expect(result, equals(expected));
    });

    test(
        'getCurrentLocation throws LocationServiceDisabledFailure when GPS is off',
        () async {
      service.isServiceEnabled = false;
      expect(
        () => service.getCurrentLocation(),
        throwsA(isA<LocationServiceDisabledFailure>()),
      );
    });

    test(
        'getCurrentLocation throws LocationPermissionDeniedFailure when permission denied',
        () async {
      service.permissionState = LocationPermissionState.denied;
      expect(
        () => service.getCurrentLocation(),
        throwsA(isA<LocationPermissionDeniedFailure>()),
      );
    });

    test(
        'getCurrentLocation throws LocationPermissionPermanentlyDeniedFailure when permanently denied',
        () async {
      service.permissionState = LocationPermissionState.permanentlyDenied;
      expect(
        () => service.getCurrentLocation(),
        throwsA(isA<LocationPermissionPermanentlyDeniedFailure>()),
      );
    });
  });
}

import 'package:cipher_x/features/location/domain/entities/location_data.dart';
import 'package:cipher_x/features/location/domain/entities/location_permission_state.dart';
import 'package:cipher_x/features/location/domain/failures/location_failure.dart';
import 'package:cipher_x/features/location/presentation/providers/location_controller.dart';
import 'package:cipher_x/features/location/presentation/providers/location_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_location_service.dart';

void main() {
  group('LocationController Unit Tests', () {
    late FakeLocationService fakeService;
    late ProviderContainer container;

    setUp(() {
      fakeService = FakeLocationService();
      container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWithValue(fakeService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is AsyncData(null)', () {
      final state = container.read(locationControllerProvider);
      expect(state, equals(const AsyncData<LocationData?>(null)));
    });

    test('fetchLocation sets state to AsyncData(LocationData) on success', () async {
      final expected = LocationData(
        latitude: 18.5204,
        longitude: 73.8567,
        accuracy: 10.0,
        timestamp: DateTime.utc(2026, 8, 28, 12, 0),
      );
      fakeService.currentLocationData = expected;

      final controller = container.read(locationControllerProvider.notifier);
      final result = await controller.fetchLocation();

      expect(result, equals(expected));
      final state = container.read(locationControllerProvider);
      expect(state.value, equals(expected));
    });

    test('fetchLocation sets state to AsyncError on LocationServiceDisabledFailure', () async {
      fakeService.isServiceEnabled = false;

      final controller = container.read(locationControllerProvider.notifier);
      final result = await controller.fetchLocation();

      expect(result, isNull);
      final state = container.read(locationControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<LocationServiceDisabledFailure>());
    });

    test('requestPermission requests permission and invalidates permission provider', () async {
      fakeService.permissionState = LocationPermissionState.denied;

      final controller = container.read(locationControllerProvider.notifier);
      final result = await controller.requestPermission();

      expect(result, equals(LocationPermissionState.granted));
    });
  });
}

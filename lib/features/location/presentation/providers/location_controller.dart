import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/location_data.dart';
import '../../domain/entities/location_permission_state.dart';
import '../../domain/services/location_service.dart';
import 'location_providers.dart';

class LocationController extends AutoDisposeAsyncNotifier<LocationData?> {
  @override
  Future<LocationData?> build() async {
    return null;
  }

  LocationService get _service => ref.read(locationServiceProvider);

  Future<LocationData?> fetchLocation({Duration? timeout}) async {
    state = const AsyncLoading();
    try {
      final location = await _service.getCurrentLocation(timeout: timeout);
      state = AsyncData(location);
      return location;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<LocationPermissionState> requestPermission() async {
    try {
      final result = await _service.requestPermission();
      ref.invalidate(locationPermissionProvider);
      return result;
    } catch (e) {
      return LocationPermissionState.unableToDetermine;
    }
  }
}

final locationControllerProvider =
    AutoDisposeAsyncNotifierProvider<LocationController, LocationData?>(() {
  return LocationController();
});

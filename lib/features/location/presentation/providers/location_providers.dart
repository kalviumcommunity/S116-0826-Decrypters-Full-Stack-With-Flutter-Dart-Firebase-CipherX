import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/geolocator_location_service.dart';
import '../../domain/entities/location_permission_state.dart';
import '../../domain/services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return const GeolocatorLocationService();
});

final locationPermissionProvider =
    FutureProvider.autoDispose<LocationPermissionState>((ref) async {
  final service = ref.watch(locationServiceProvider);
  return await service.checkPermission();
});

final isLocationServiceEnabledProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final service = ref.watch(locationServiceProvider);
  return await service.isLocationServiceEnabled();
});

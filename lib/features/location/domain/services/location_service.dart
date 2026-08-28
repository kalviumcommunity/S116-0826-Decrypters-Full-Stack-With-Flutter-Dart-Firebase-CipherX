import '../entities/location_data.dart';
import '../entities/location_permission_state.dart';

abstract class LocationService {
  Future<LocationPermissionState> checkPermission();
  Future<LocationPermissionState> requestPermission();
  Future<bool> isLocationServiceEnabled();
  Future<LocationData> getCurrentLocation({Duration? timeout});
}

import 'package:cipher_x/features/location/domain/entities/location_data.dart';
import 'package:cipher_x/features/location/domain/entities/location_permission_state.dart';
import 'package:cipher_x/features/location/domain/failures/location_failure.dart';
import 'package:cipher_x/features/location/domain/services/location_service.dart';

class FakeLocationService implements LocationService {
  LocationPermissionState permissionState;
  bool isServiceEnabled;
  LocationData? currentLocationData;
  LocationFailure? failureToThrow;

  FakeLocationService({
    this.permissionState = LocationPermissionState.granted,
    this.isServiceEnabled = true,
    this.currentLocationData,
    this.failureToThrow,
  });

  @override
  Future<LocationPermissionState> checkPermission() async {
    if (failureToThrow != null) throw failureToThrow!;
    return permissionState;
  }

  @override
  Future<LocationPermissionState> requestPermission() async {
    if (failureToThrow != null) throw failureToThrow!;
    if (permissionState == LocationPermissionState.denied) {
      permissionState = LocationPermissionState.granted;
    }
    return permissionState;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    if (failureToThrow != null) throw failureToThrow!;
    return isServiceEnabled;
  }

  @override
  Future<LocationData> getCurrentLocation({Duration? timeout}) async {
    if (failureToThrow != null) throw failureToThrow!;
    if (!isServiceEnabled) {
      throw const LocationServiceDisabledFailure();
    }
    if (permissionState == LocationPermissionState.denied) {
      throw const LocationPermissionDeniedFailure();
    }
    if (permissionState == LocationPermissionState.permanentlyDenied) {
      throw const LocationPermissionPermanentlyDeniedFailure();
    }
    if (currentLocationData != null) {
      return currentLocationData!;
    }
    return LocationData(
      latitude: 18.5204,
      longitude: 73.8567,
      accuracy: 10.0,
      timestamp: DateTime.utc(2026, 8, 28, 12, 0),
    );
  }
}

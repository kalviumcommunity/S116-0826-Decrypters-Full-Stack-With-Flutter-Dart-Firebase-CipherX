import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../domain/entities/location_data.dart';
import '../../domain/entities/location_permission_state.dart';
import '../../domain/failures/location_failure.dart';
import '../../domain/services/location_service.dart';

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LocationPermissionState> checkPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return _mapPermission(permission);
    } catch (e) {
      return LocationPermissionState.unableToDetermine;
    }
  }

  @override
  Future<LocationPermissionState> requestPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      return _mapPermission(permission);
    } catch (e) {
      return LocationPermissionState.unableToDetermine;
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<LocationData> getCurrentLocation({Duration? timeout}) async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledFailure();
    }

    var permission = await checkPermission();
    if (permission == LocationPermissionState.denied) {
      permission = await requestPermission();
    }

    if (permission == LocationPermissionState.denied) {
      throw const LocationPermissionDeniedFailure();
    }

    if (permission == LocationPermissionState.permanentlyDenied) {
      throw const LocationPermissionPermanentlyDeniedFailure();
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: timeout ?? const Duration(seconds: 15),
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
        altitude: position.altitude,
        speed: position.speed,
      );
    } on TimeoutException {
      throw const LocationTimeoutFailure();
    } on LocationServiceDisabledException {
      throw const LocationServiceDisabledFailure();
    } on PermissionDeniedException {
      throw const LocationPermissionDeniedFailure();
    } catch (e) {
      if (e is LocationFailure) rethrow;
      throw UnknownLocationFailure(e.toString());
    }
  }

  LocationPermissionState _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionState.granted;
      case LocationPermission.denied:
        return LocationPermissionState.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionState.permanentlyDenied;
      case LocationPermission.unableToDetermine:
        return LocationPermissionState.unableToDetermine;
    }
  }
}

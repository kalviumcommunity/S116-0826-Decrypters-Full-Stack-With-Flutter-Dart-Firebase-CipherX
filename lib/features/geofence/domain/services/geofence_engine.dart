import 'dart:math';

import '../../../location/domain/entities/location_data.dart';
import '../../../sites/domain/entities/site.dart';
import '../entities/geofence_result.dart';

/// Pure domain engine for calculating distance and evaluating geofence decisions.
///
/// This engine is completely decoupled from device GPS services, camera, navigation,
/// and backend databases.
class GeofenceEngine {
  /// Earth's mean radius in meters.
  static const double earthRadiusMeters = 6371000.0;

  /// Default maximum allowed GPS accuracy in meters.
  /// Location readings with accuracy uncertainty larger than this value
  /// are considered too poor for a reliable geofence decision.
  static const double defaultMaxAccuracyThresholdMeters = 50.0;

  const GeofenceEngine();

  /// Calculates the geographic distance in meters between two lat/lng coordinates
  /// using the Haversine formula.
  double calculateDistanceMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    if (!startLatitude.isFinite ||
        startLatitude < -90.0 ||
        startLatitude > 90.0 ||
        !startLongitude.isFinite ||
        startLongitude < -180.0 ||
        startLongitude > 180.0 ||
        !endLatitude.isFinite ||
        endLatitude < -90.0 ||
        endLatitude > 90.0 ||
        !endLongitude.isFinite ||
        endLongitude < -180.0 ||
        endLongitude > 180.0) {
      return double.nan;
    }

    final dLat = _toRadians(endLatitude - startLatitude);
    final dLng = _toRadians(endLongitude - startLongitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(startLatitude)) *
            cos(_toRadians(endLatitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Evaluates guard location against site location and radius, considering GPS accuracy.
  ///
  /// Boundary Rule: Exact boundary condition (`distance == radius`) is treated as INSIDE (`distance <= radius`).
  GeofenceResult evaluate({
    required double guardLatitude,
    required double guardLongitude,
    required double guardAccuracy,
    required double siteLatitude,
    required double siteLongitude,
    required double siteRadius,
    double maxAccuracyThreshold = defaultMaxAccuracyThresholdMeters,
  }) {
    // 1. Validate inputs
    if (!guardLatitude.isFinite ||
        guardLatitude < -90.0 ||
        guardLatitude > 90.0) {
      return GeofenceResult(
        status: GeofenceStatus.invalidInput,
        distanceMeters: double.nan,
        radiusMeters: siteRadius,
        accuracyMeters: guardAccuracy,
        message: 'Invalid guard latitude: must be between -90 and 90 degrees.',
      );
    }

    if (!guardLongitude.isFinite ||
        guardLongitude < -180.0 ||
        guardLongitude > 180.0) {
      return GeofenceResult(
        status: GeofenceStatus.invalidInput,
        distanceMeters: double.nan,
        radiusMeters: siteRadius,
        accuracyMeters: guardAccuracy,
        message:
            'Invalid guard longitude: must be between -180 and 180 degrees.',
      );
    }

    if (!siteLatitude.isFinite || siteLatitude < -90.0 || siteLatitude > 90.0) {
      return GeofenceResult(
        status: GeofenceStatus.invalidInput,
        distanceMeters: double.nan,
        radiusMeters: siteRadius,
        accuracyMeters: guardAccuracy,
        message: 'Invalid site latitude: must be between -90 and 90 degrees.',
      );
    }

    if (!siteLongitude.isFinite ||
        siteLongitude < -180.0 ||
        siteLongitude > 180.0) {
      return GeofenceResult(
        status: GeofenceStatus.invalidInput,
        distanceMeters: double.nan,
        radiusMeters: siteRadius,
        accuracyMeters: guardAccuracy,
        message:
            'Invalid site longitude: must be between -180 and 180 degrees.',
      );
    }

    if (!siteRadius.isFinite || siteRadius <= 0.0) {
      return GeofenceResult(
        status: GeofenceStatus.invalidInput,
        distanceMeters: double.nan,
        radiusMeters: siteRadius,
        accuracyMeters: guardAccuracy,
        message: 'Invalid site geofence radius: must be greater than zero.',
      );
    }

    if (!guardAccuracy.isFinite || guardAccuracy < 0.0) {
      return GeofenceResult(
        status: GeofenceStatus.invalidInput,
        distanceMeters: double.nan,
        radiusMeters: siteRadius,
        accuracyMeters: guardAccuracy,
        message: 'Invalid guard GPS accuracy: must be non-negative.',
      );
    }

    // 2. Calculate geographic distance
    final distance = calculateDistanceMeters(
      startLatitude: guardLatitude,
      startLongitude: guardLongitude,
      endLatitude: siteLatitude,
      endLongitude: siteLongitude,
    );

    if (distance.isNaN) {
      return GeofenceResult(
        status: GeofenceStatus.invalidInput,
        distanceMeters: double.nan,
        radiusMeters: siteRadius,
        accuracyMeters: guardAccuracy,
        message: 'Failed to calculate distance for provided coordinates.',
      );
    }

    // 3. Evaluate GPS accuracy threshold rule
    // If reported GPS accuracy is worse than maxAccuracyThreshold or exceeds site radius, return poor accuracy
    final effectiveAccuracyLimit = min(maxAccuracyThreshold, siteRadius);
    if (guardAccuracy > effectiveAccuracyLimit) {
      return GeofenceResult(
        status: GeofenceStatus.poorAccuracy,
        distanceMeters: distance,
        radiusMeters: siteRadius,
        accuracyMeters: guardAccuracy,
        message:
            'GPS accuracy (${guardAccuracy.toStringAsFixed(1)}m) is too poor for a reliable geofence decision (threshold: ${effectiveAccuracyLimit.toStringAsFixed(1)}m).',
      );
    }

    // 4. Evaluate radius decision (distance <= radius is INSIDE per boundary requirement)
    final isInside = distance <= siteRadius;

    return GeofenceResult(
      status: isInside ? GeofenceStatus.inside : GeofenceStatus.outside,
      distanceMeters: distance,
      radiusMeters: siteRadius,
      accuracyMeters: guardAccuracy,
      message: isInside
          ? 'Guard is within site geofence radius (${distance.toStringAsFixed(1)}m <= ${siteRadius.toStringAsFixed(1)}m).'
          : 'Guard is outside site geofence radius (${distance.toStringAsFixed(1)}m > ${siteRadius.toStringAsFixed(1)}m).',
    );
  }

  /// Convenience wrapper evaluating a [LocationData] against a [Site].
  GeofenceResult evaluateWithLocationAndSite({
    required LocationData location,
    required Site site,
    double maxAccuracyThreshold = defaultMaxAccuracyThresholdMeters,
  }) {
    return evaluate(
      guardLatitude: location.latitude,
      guardLongitude: location.longitude,
      guardAccuracy: location.accuracy,
      siteLatitude: site.latitude,
      siteLongitude: site.longitude,
      siteRadius: site.geofenceRadius,
      maxAccuracyThreshold: maxAccuracyThreshold,
    );
  }

  static double _toRadians(double degree) => degree * pi / 180.0;
}

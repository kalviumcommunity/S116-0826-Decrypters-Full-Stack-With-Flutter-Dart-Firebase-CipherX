import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/geofence/domain/entities/geofence_result.dart';
import 'package:cipher_x/features/geofence/domain/services/geofence_engine.dart';
import 'package:cipher_x/features/location/domain/entities/location_data.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';

void main() {
  late GeofenceEngine engine;

  // San Francisco reference coordinates
  const siteLat = 37.7749;
  const siteLng = -122.4194;
  const siteRadius = 100.0; // 100 meters

  setUp(() {
    engine = const GeofenceEngine();
  });

  group('GeofenceEngine — Distance Calculation', () {
    test('calculates 0 meters for identical coordinates', () {
      final distance = engine.calculateDistanceMeters(
        startLatitude: siteLat,
        startLongitude: siteLng,
        endLatitude: siteLat,
        endLongitude: siteLng,
      );

      expect(distance, equals(0.0));
    });

    test('calculates deterministic geographic distance between two points', () {
      // Point ~111 meters North (approx +0.001 deg latitude)
      final distance = engine.calculateDistanceMeters(
        startLatitude: siteLat,
        startLongitude: siteLng,
        endLatitude: siteLat + 0.001,
        endLongitude: siteLng,
      );

      expect(distance, greaterThan(110.0));
      expect(distance, lessThan(112.0));
    });

    test('calculates known real-world benchmark distance between two landmarks',
        () {
      // SF Union Square (37.7879, -122.4075) to SF Ferry Building (37.7955, -122.3937)
      // Known geodesic distance is approximately 1.48 km (1470-1500m)
      final distance = engine.calculateDistanceMeters(
        startLatitude: 37.7879,
        startLongitude: -122.4075,
        endLatitude: 37.7955,
        endLongitude: -122.3937,
      );

      expect(distance, greaterThan(1450.0));
      expect(distance, lessThan(1510.0));
    });

    test('clamps floating-point precision on extreme antipodal coordinates', () {
      // North pole to South pole (~20,015 km)
      final distance = engine.calculateDistanceMeters(
        startLatitude: 90.0,
        startLongitude: 0.0,
        endLatitude: -90.0,
        endLongitude: 0.0,
      );

      expect(distance.isFinite, isTrue);
      expect(distance, closeTo(20015086.0, 1000.0));
    });
  });

  group('GeofenceEngine — Required PR #21 Engine Tests', () {
    test(
        'TEST 1 — INSIDE RADIUS: Guard location inside radius returns inside status',
        () {
      // Guard is ~11 meters from site center (site radius = 100m)
      final result = engine.evaluate(
        guardLatitude: siteLat + 0.0001,
        guardLongitude: siteLng,
        guardAccuracy: 5.0,
        siteLatitude: siteLat,
        siteLongitude: siteLng,
        siteRadius: siteRadius,
      );

      expect(result.status, equals(GeofenceStatus.inside));
      expect(result.isWithinGeofence, isTrue);
      expect(result.distanceMeters, lessThan(siteRadius));
      expect(result.radiusMeters, equals(siteRadius));
      expect(result.accuracyMeters, equals(5.0));
    });

    test(
        'TEST 2 — OUTSIDE RADIUS: Guard location outside radius returns outside status',
        () {
      // Guard is ~550 meters away from site center (site radius = 100m)
      final result = engine.evaluate(
        guardLatitude: siteLat + 0.005,
        guardLongitude: siteLng,
        guardAccuracy: 5.0,
        siteLatitude: siteLat,
        siteLongitude: siteLng,
        siteRadius: siteRadius,
      );

      expect(result.status, equals(GeofenceStatus.outside));
      expect(result.isWithinGeofence, isFalse);
      expect(result.isOutside, isTrue);
      expect(result.distanceMeters, greaterThan(siteRadius));
      expect(result.radiusMeters, equals(siteRadius));
    });

    test(
        'TEST 3 — BOUNDARY CONDITION: Exact boundary distance == radius is treated as INSIDE (distance <= radius)',
        () {
      // Calculate exact distance for a given guard position
      final calculatedDistance = engine.calculateDistanceMeters(
        startLatitude: siteLat,
        startLongitude: siteLng,
        endLatitude: siteLat + 0.0005,
        endLongitude: siteLng,
      );

      // Evaluate using siteRadius set to exactly the calculated distance
      final result = engine.evaluate(
        guardLatitude: siteLat + 0.0005,
        guardLongitude: siteLng,
        guardAccuracy: 2.0,
        siteLatitude: siteLat,
        siteLongitude: siteLng,
        siteRadius: calculatedDistance, // distance == radius
      );

      // Per requirements: distance <= radius means boundary is INSIDE
      expect(result.status, equals(GeofenceStatus.inside));
      expect(result.isWithinGeofence, isTrue);
      expect(result.distanceMeters, closeTo(calculatedDistance, 0.0001));
      expect(result.radiusMeters, closeTo(calculatedDistance, 0.0001));
    });

    test(
        'TEST 4 — POOR GPS ACCURACY: High uncertainty returns poorAccuracy result',
        () {
      // Guard is close (11m away), but reported GPS accuracy uncertainty is 80m (> max 50m threshold)
      final result = engine.evaluate(
        guardLatitude: siteLat + 0.0001,
        guardLongitude: siteLng,
        guardAccuracy: 80.0, // Poor accuracy
        siteLatitude: siteLat,
        siteLongitude: siteLng,
        siteRadius: siteRadius,
        maxAccuracyThreshold: 50.0,
      );

      expect(result.status, equals(GeofenceStatus.poorAccuracy));
      expect(result.isPoorAccuracy, isTrue);
      expect(result.isWithinGeofence, isFalse);
      expect(result.message, contains('GPS accuracy (80.0m) is too poor'));
    });

    test(
        'Small site radius (e.g. 15m) does not falsely trigger poorAccuracy when GPS accuracy is within threshold',
        () {
      // Guard standing 5m from site center with normal 12m mobile GPS accuracy
      final result = engine.evaluate(
        guardLatitude: siteLat + 0.000045,
        guardLongitude: siteLng,
        guardAccuracy: 12.0,
        siteLatitude: siteLat,
        siteLongitude: siteLng,
        siteRadius: 15.0, // 15 meter small radius
        maxAccuracyThreshold: 50.0,
      );

      // 12m <= 50m max threshold, and 5m <= 15m radius -> successfully INSIDE
      expect(result.status, equals(GeofenceStatus.inside));
      expect(result.isWithinGeofence, isTrue);
      expect(result.distanceMeters, lessThan(15.0));
    });
  });

  group('GeofenceEngine — Invalid Input Handling', () {
    test('handles invalid guard latitude gracefully without crashing', () {
      final result = engine.evaluate(
        guardLatitude: 120.0, // Invalid lat > 90
        guardLongitude: siteLng,
        guardAccuracy: 5.0,
        siteLatitude: siteLat,
        siteLongitude: siteLng,
        siteRadius: siteRadius,
      );

      expect(result.status, equals(GeofenceStatus.invalidInput));
      expect(result.isInvalidInput, isTrue);
      expect(result.isWithinGeofence, isFalse);
    });

    test('handles invalid guard longitude gracefully without crashing', () {
      final result = engine.evaluate(
        guardLatitude: siteLat,
        guardLongitude: -200.0, // Invalid lng < -180
        guardAccuracy: 5.0,
        siteLatitude: siteLat,
        siteLongitude: siteLng,
        siteRadius: siteRadius,
      );

      expect(result.status, equals(GeofenceStatus.invalidInput));
      expect(result.isInvalidInput, isTrue);
    });

    test('handles invalid site geofence radius gracefully without crashing',
        () {
      final result = engine.evaluate(
        guardLatitude: siteLat,
        guardLongitude: siteLng,
        guardAccuracy: 5.0,
        siteLatitude: siteLat,
        siteLongitude: siteLng,
        siteRadius: -10.0, // Invalid negative radius
      );

      expect(result.status, equals(GeofenceStatus.invalidInput));
      expect(result.isInvalidInput, isTrue);
    });

    test('handles negative guard accuracy gracefully without crashing', () {
      final result = engine.evaluate(
        guardLatitude: siteLat,
        guardLongitude: siteLng,
        guardAccuracy: -5.0, // Invalid accuracy
        siteLatitude: siteLat,
        siteLongitude: siteLng,
        siteRadius: siteRadius,
      );

      expect(result.status, equals(GeofenceStatus.invalidInput));
      expect(result.isInvalidInput, isTrue);
    });
  });

  group('GeofenceEngine — LocationData & Site Integration', () {
    test('evaluates with LocationData and Site entity objects', () {
      final location = LocationData(
        latitude: siteLat,
        longitude: siteLng,
        accuracy: 4.0,
        timestamp: DateTime.now(),
      );

      const site = Site(
        siteId: 'site_1',
        organizationId: 'org_1',
        name: 'Headquarters',
        address: '123 Tech St',
        latitude: siteLat,
        longitude: siteLng,
        geofenceRadius: 50.0,
      );

      final result = engine.evaluateWithLocationAndSite(
        location: location,
        site: site,
      );

      expect(result.status, equals(GeofenceStatus.inside));
      expect(result.isWithinGeofence, isTrue);
      expect(result.distanceMeters, equals(0.0));
      expect(result.radiusMeters, equals(50.0));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/geofence/domain/entities/geofence_result.dart';

void main() {
  group('GeofenceResult Entity Unit Tests', () {
    test('supports value equality with valid numbers', () {
      const result1 = GeofenceResult(
        status: GeofenceStatus.inside,
        distanceMeters: 45.5,
        radiusMeters: 100.0,
        accuracyMeters: 5.0,
        message: 'Inside',
      );

      const result2 = GeofenceResult(
        status: GeofenceStatus.inside,
        distanceMeters: 45.5,
        radiusMeters: 100.0,
        accuracyMeters: 5.0,
        message: 'Inside',
      );

      expect(result1, equals(result2));
      expect(result1.hashCode, equals(result2.hashCode));
    });

    test('supports reflexive and symmetric equality when distanceMeters is NaN',
        () {
      const result1 = GeofenceResult(
        status: GeofenceStatus.invalidInput,
        distanceMeters: double.nan,
        radiusMeters: 100.0,
        accuracyMeters: 5.0,
        message: 'Invalid coordinates',
      );

      const result2 = GeofenceResult(
        status: GeofenceStatus.invalidInput,
        distanceMeters: double.nan,
        radiusMeters: 100.0,
        accuracyMeters: 5.0,
        message: 'Invalid coordinates',
      );

      // Reflexive
      expect(result1, equals(result1));
      // Symmetric
      expect(result1, equals(result2));
      expect(result2, equals(result1));
      expect(result1.hashCode, equals(result2.hashCode));
    });

    test('boolean status flags reflect status accurately', () {
      const inside = GeofenceResult(
        status: GeofenceStatus.inside,
        distanceMeters: 10.0,
        radiusMeters: 50.0,
        accuracyMeters: 3.0,
      );
      expect(inside.isWithinGeofence, isTrue);
      expect(inside.isOutside, isFalse);
      expect(inside.isPoorAccuracy, isFalse);
      expect(inside.isInvalidInput, isFalse);

      const outside = GeofenceResult(
        status: GeofenceStatus.outside,
        distanceMeters: 75.0,
        radiusMeters: 50.0,
        accuracyMeters: 3.0,
      );
      expect(outside.isWithinGeofence, isFalse);
      expect(outside.isOutside, isTrue);

      const poorAcc = GeofenceResult(
        status: GeofenceStatus.poorAccuracy,
        distanceMeters: 20.0,
        radiusMeters: 50.0,
        accuracyMeters: 80.0,
      );
      expect(poorAcc.isPoorAccuracy, isTrue);

      const invalid = GeofenceResult(
        status: GeofenceStatus.invalidInput,
        distanceMeters: double.nan,
        radiusMeters: 50.0,
        accuracyMeters: 3.0,
      );
      expect(invalid.isInvalidInput, isTrue);
    });

    test('copyWith updates specified fields cleanly', () {
      const original = GeofenceResult(
        status: GeofenceStatus.outside,
        distanceMeters: 120.0,
        radiusMeters: 100.0,
        accuracyMeters: 10.0,
        message: 'Outside',
      );

      final updated = original.copyWith(
        status: GeofenceStatus.inside,
        distanceMeters: 80.0,
      );

      expect(updated.status, equals(GeofenceStatus.inside));
      expect(updated.distanceMeters, equals(80.0));
      expect(updated.radiusMeters, equals(100.0));
      expect(updated.accuracyMeters, equals(10.0));
      expect(updated.message, equals('Outside'));
    });

    test('toString formats clean string representation including NaN safety',
        () {
      const valid = GeofenceResult(
        status: GeofenceStatus.inside,
        distanceMeters: 15.25,
        radiusMeters: 50.0,
        accuracyMeters: 5.0,
        message: 'Inside',
      );
      expect(valid.toString(), contains('distance: 15.25m'));

      const withNan = GeofenceResult(
        status: GeofenceStatus.invalidInput,
        distanceMeters: double.nan,
        radiusMeters: 50.0,
        accuracyMeters: 5.0,
      );
      expect(withNan.toString(), contains('distance: NaN'));
    });
  });
}

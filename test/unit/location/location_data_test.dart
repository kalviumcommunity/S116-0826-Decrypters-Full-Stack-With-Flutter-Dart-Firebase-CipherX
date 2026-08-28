import 'package:cipher_x/features/location/domain/entities/location_data.dart';
import 'package:cipher_x/features/location/domain/failures/location_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocationData Unit Tests', () {
    final now = DateTime.utc(2026, 8, 28, 12, 0);

    test('creates valid LocationData object', () {
      final loc = LocationData(
        latitude: 18.5204,
        longitude: 73.8567,
        accuracy: 12.5,
        timestamp: now,
      );

      expect(loc.latitude, equals(18.5204));
      expect(loc.longitude, equals(73.8567));
      expect(loc.accuracy, equals(12.5));
      expect(loc.timestamp, equals(now));
    });

    test('throws InvalidLocationCoordinatesFailure for out of range latitude', () {
      expect(
        () => LocationData(
          latitude: 90.1,
          longitude: 73.8567,
          accuracy: 10.0,
          timestamp: now,
        ),
        throwsA(isA<InvalidLocationCoordinatesFailure>()),
      );

      expect(
        () => LocationData(
          latitude: -90.5,
          longitude: 73.8567,
          accuracy: 10.0,
          timestamp: now,
        ),
        throwsA(isA<InvalidLocationCoordinatesFailure>()),
      );
    });

    test('throws InvalidLocationCoordinatesFailure for out of range longitude', () {
      expect(
        () => LocationData(
          latitude: 18.5204,
          longitude: 180.1,
          accuracy: 10.0,
          timestamp: now,
        ),
        throwsA(isA<InvalidLocationCoordinatesFailure>()),
      );

      expect(
        () => LocationData(
          latitude: 18.5204,
          longitude: -180.5,
          accuracy: 10.0,
          timestamp: now,
        ),
        throwsA(isA<InvalidLocationCoordinatesFailure>()),
      );
    });

    test('throws InvalidLocationCoordinatesFailure for NaN or Infinity values', () {
      expect(
        () => LocationData(
          latitude: double.nan,
          longitude: 73.8567,
          accuracy: 10.0,
          timestamp: now,
        ),
        throwsA(isA<InvalidLocationCoordinatesFailure>()),
      );

      expect(
        () => LocationData(
          latitude: 18.5204,
          longitude: double.infinity,
          accuracy: 10.0,
          timestamp: now,
        ),
        throwsA(isA<InvalidLocationCoordinatesFailure>()),
      );

      expect(
        () => LocationData(
          latitude: 18.5204,
          longitude: 73.8567,
          accuracy: double.nan,
          timestamp: now,
        ),
        throwsA(isA<InvalidLocationCoordinatesFailure>()),
      );
    });

    test('throws InvalidLocationCoordinatesFailure for negative accuracy', () {
      expect(
        () => LocationData(
          latitude: 18.5204,
          longitude: 73.8567,
          accuracy: -5.0,
          timestamp: now,
        ),
        throwsA(isA<InvalidLocationCoordinatesFailure>()),
      );
    });

    test('supports value equality and copyWith', () {
      final loc1 = LocationData(
        latitude: 18.5204,
        longitude: 73.8567,
        accuracy: 12.5,
        timestamp: now,
      );

      final loc2 = LocationData(
        latitude: 18.5204,
        longitude: 73.8567,
        accuracy: 12.5,
        timestamp: now,
      );

      expect(loc1, equals(loc2));
      expect(loc1.hashCode, equals(loc2.hashCode));

      final updated = loc1.copyWith(accuracy: 5.0);
      expect(updated.accuracy, equals(5.0));
      expect(updated.latitude, equals(loc1.latitude));
    });

    test('serializes to Map and deserializes cleanly', () {
      final loc = LocationData(
        latitude: 18.5204,
        longitude: 73.8567,
        accuracy: 12.5,
        timestamp: now,
      );

      final map = loc.toMap();
      expect(map['latitude'], equals(18.5204));
      expect(map['longitude'], equals(73.8567));
      expect(map['accuracy'], equals(12.5));

      final restored = LocationData.fromMap(map);
      expect(restored, equals(loc));
    });
  });
}

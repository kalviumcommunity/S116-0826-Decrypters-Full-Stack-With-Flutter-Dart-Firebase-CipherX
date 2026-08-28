import 'package:cipher_x/features/location/data/services/geolocator_location_service.dart';
import 'package:cipher_x/features/location/domain/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeolocatorLocationService Unit Tests', () {
    late GeolocatorLocationService service;

    setUp(() {
      service = const GeolocatorLocationService();
    });

    test('implements LocationService interface', () {
      expect(service, isA<LocationService>());
    });

    test('const constructor creates valid instance', () {
      const s1 = GeolocatorLocationService();
      const s2 = GeolocatorLocationService();
      expect(s1, equals(s2));
    });
  });
}

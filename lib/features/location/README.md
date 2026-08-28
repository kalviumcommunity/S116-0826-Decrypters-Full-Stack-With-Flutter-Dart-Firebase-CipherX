# Cipher-X Location Service Domain Foundation

This module provides the production-grade Location Service foundation for Cipher-X attendance verification, geofencing, and check-in workflows.

## Architecture

```
Presentation Layer (Widgets & Controllers)
       ↓
LocationController / locationServiceProvider (Riverpod)
       ↓
LocationService (Domain Interface)
       ↓
GeolocatorLocationService (Data / Infrastructure)
       ↓
Native Device GPS (Platform APIs)
```

## Key Components

- **`LocationData`**: Value object encapsulating `latitude`, `longitude`, `accuracy`, and `timestamp`. Strict validation rejects `NaN`, `Infinity`, or out-of-range coordinates (`-90 <= lat <= 90`, `-180 <= lng <= 180`).
- **`LocationPermissionState`**: Domain enum (`granted`, `denied`, `permanentlyDenied`, `unableToDetermine`).
- **`LocationFailure`**: Sealed hierarchy of domain exceptions (`LocationPermissionDeniedFailure`, `LocationServiceDisabledFailure`, `LocationTimeoutFailure`, `InvalidLocationCoordinatesFailure`, `UnknownLocationFailure`).
- **`LocationService`**: Clean domain interface defining permission and position acquisition contracts.
- **`GeolocatorLocationService`**: Production implementation wrapping the `geolocator` plugin.
- **`LocationStatusCard`**: Reusable Material 3 UI component for location status verification.

## Testing Harness

For unit and widget testing, use `FakeLocationService` located in `test/fakes/fake_location_service.dart`.

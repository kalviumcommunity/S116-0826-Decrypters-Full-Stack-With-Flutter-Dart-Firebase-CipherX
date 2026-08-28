import 'package:meta/meta.dart';

@immutable
sealed class LocationFailure implements Exception {
  final String message;
  const LocationFailure(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationFailure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => '$runtimeType: $message';
}

final class LocationPermissionDeniedFailure extends LocationFailure {
  const LocationPermissionDeniedFailure([
    super.message = 'Location permission was denied by the user.',
  ]);
}

final class LocationPermissionPermanentlyDeniedFailure
    extends LocationFailure {
  const LocationPermissionPermanentlyDeniedFailure([
    super.message =
        'Location permission is permanently denied. Please enable it in device settings.',
  ]);
}

final class LocationServiceDisabledFailure extends LocationFailure {
  const LocationServiceDisabledFailure([
    super.message = 'GPS / Location services are disabled on this device.',
  ]);
}

final class LocationTimeoutFailure extends LocationFailure {
  const LocationTimeoutFailure([
    super.message = 'Location request timed out while acquiring GPS position.',
  ]);
}

final class InvalidLocationCoordinatesFailure extends LocationFailure {
  const InvalidLocationCoordinatesFailure([
    super.message = 'Acquired location coordinates are out of valid range.',
  ]);
}

final class UnknownLocationFailure extends LocationFailure {
  const UnknownLocationFailure([
    super.message = 'An unexpected location error occurred.',
  ]);
}

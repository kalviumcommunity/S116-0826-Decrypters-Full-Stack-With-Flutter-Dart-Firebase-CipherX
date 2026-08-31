import 'package:meta/meta.dart';

enum GeofenceStatus {
  inside,
  outside,
  poorAccuracy,
  invalidInput,
}

@immutable
class GeofenceResult {
  final GeofenceStatus status;
  final double distanceMeters;
  final double radiusMeters;
  final double accuracyMeters;
  final String? message;

  const GeofenceResult({
    required this.status,
    required this.distanceMeters,
    required this.radiusMeters,
    required this.accuracyMeters,
    this.message,
  });

  bool get isWithinGeofence => status == GeofenceStatus.inside;
  bool get isOutside => status == GeofenceStatus.outside;
  bool get isPoorAccuracy => status == GeofenceStatus.poorAccuracy;
  bool get isInvalidInput => status == GeofenceStatus.invalidInput;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeofenceResult &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          distanceMeters == other.distanceMeters &&
          radiusMeters == other.radiusMeters &&
          accuracyMeters == other.accuracyMeters &&
          message == other.message;

  @override
  int get hashCode =>
      status.hashCode ^
      distanceMeters.hashCode ^
      radiusMeters.hashCode ^
      accuracyMeters.hashCode ^
      message.hashCode;

  @override
  String toString() {
    return 'GeofenceResult(status: $status, distance: ${distanceMeters.toStringAsFixed(2)}m, radius: ${radiusMeters.toStringAsFixed(2)}m, accuracy: ${accuracyMeters.toStringAsFixed(2)}m, message: $message)';
  }
}

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

  GeofenceResult copyWith({
    GeofenceStatus? status,
    double? distanceMeters,
    double? radiusMeters,
    double? accuracyMeters,
    String? message,
  }) {
    return GeofenceResult(
      status: status ?? this.status,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      message: message ?? this.message,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeofenceResult &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          (distanceMeters == other.distanceMeters ||
              (distanceMeters.isNaN && other.distanceMeters.isNaN)) &&
          (radiusMeters == other.radiusMeters ||
              (radiusMeters.isNaN && other.radiusMeters.isNaN)) &&
          (accuracyMeters == other.accuracyMeters ||
              (accuracyMeters.isNaN && other.accuracyMeters.isNaN)) &&
          message == other.message;

  @override
  int get hashCode => Object.hash(
        status,
        distanceMeters.isNaN ? 'NaN' : distanceMeters,
        radiusMeters.isNaN ? 'NaN' : radiusMeters,
        accuracyMeters.isNaN ? 'NaN' : accuracyMeters,
        message,
      );

  @override
  String toString() {
    final distStr =
        distanceMeters.isNaN ? 'NaN' : '${distanceMeters.toStringAsFixed(2)}m';
    final radStr =
        radiusMeters.isNaN ? 'NaN' : '${radiusMeters.toStringAsFixed(2)}m';
    final accStr =
        accuracyMeters.isNaN ? 'NaN' : '${accuracyMeters.toStringAsFixed(2)}m';
    return 'GeofenceResult(status: $status, distance: $distStr, radius: $radStr, accuracy: $accStr, message: $message)';
  }
}

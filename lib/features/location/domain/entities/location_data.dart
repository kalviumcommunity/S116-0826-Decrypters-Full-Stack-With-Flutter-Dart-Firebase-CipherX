import 'package:meta/meta.dart';
import '../failures/location_failure.dart';

@immutable
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final double? altitude;
  final double? speed;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.altitude,
    this.speed,
  }) {
    if (!latitude.isFinite || latitude < -90.0 || latitude > 90.0) {
      throw const InvalidLocationCoordinatesFailure(
        'Latitude must be a finite number between -90 and 90 degrees.',
      );
    }
    if (!longitude.isFinite || longitude < -180.0 || longitude > 180.0) {
      throw const InvalidLocationCoordinatesFailure(
        'Longitude must be a finite number between -180 and 180 degrees.',
      );
    }
    if (!accuracy.isFinite || accuracy < 0.0) {
      throw const InvalidLocationCoordinatesFailure(
        'Accuracy must be a non-negative finite number.',
      );
    }
  }

  LocationData copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? timestamp,
    double? altitude,
    double? speed,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      if (altitude != null) 'altitude': altitude,
      if (speed != null) 'speed': speed,
    };
  }

  factory LocationData.fromMap(Map<String, dynamic> map) {
    final rawLat = map['latitude'];
    final rawLng = map['longitude'];
    final rawAcc = map['accuracy'];
    final rawTime = map['timestamp'];

    final latitude = rawLat is num ? rawLat.toDouble() : double.nan;
    final longitude = rawLng is num ? rawLng.toDouble() : double.nan;
    final accuracy = rawAcc is num ? rawAcc.toDouble() : double.nan;
    final timestamp =
        rawTime != null ? DateTime.parse(rawTime.toString()) : DateTime.now();

    return LocationData(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      timestamp: timestamp,
      altitude: map['altitude'] is num ? (map['altitude'] as num).toDouble() : null,
      speed: map['speed'] is num ? (map['speed'] as num).toDouble() : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationData &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          accuracy == other.accuracy &&
          timestamp == other.timestamp &&
          altitude == other.altitude &&
          speed == other.speed;

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      accuracy.hashCode ^
      timestamp.hashCode ^
      altitude.hashCode ^
      speed.hashCode;

  @override
  String toString() =>
      'LocationData(lat: $latitude, lng: $longitude, accuracy: ${accuracy}m, time: $timestamp)';
}

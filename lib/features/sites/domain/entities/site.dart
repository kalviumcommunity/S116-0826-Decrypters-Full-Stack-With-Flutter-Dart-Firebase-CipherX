import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum SiteStatus {
  active,
  inactive;

  String toMapString() => name;

  static SiteStatus fromMapString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return SiteStatus.active;
      case 'inactive':
        return SiteStatus.inactive;
      default:
        throw FormatException('Invalid SiteStatus value: $value');
    }
  }
}

@immutable
class Site {
  final String siteId;
  final String organizationId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double geofenceRadius;
  final SiteStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Site({
    required this.siteId,
    required this.organizationId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.geofenceRadius,
    this.status = SiteStatus.active,
    this.createdAt,
    this.updatedAt,
  });

  Site copyWith({
    String? siteId,
    String? organizationId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? geofenceRadius,
    SiteStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Site(
      siteId: siteId ?? this.siteId,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geofenceRadius: geofenceRadius ?? this.geofenceRadius,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'siteId': siteId,
      'id': siteId,
      'organizationId': organizationId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'geofenceRadius': geofenceRadius,
      'status': status.toMapString(),
      'isActive': status == SiteStatus.active,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  factory Site.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    double parseDouble(dynamic val, {double defaultValue = 0.0}) {
      if (val == null) return defaultValue;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? defaultValue;
      return defaultValue;
    }

    final statusStr = map['status'] as String?;
    final isActiveBool = map['isActive'] as bool?;

    final parsedStatus = statusStr != null
        ? SiteStatus.fromMapString(statusStr)
        : (isActiveBool == false ? SiteStatus.inactive : SiteStatus.active);

    return Site(
      siteId: map['siteId'] as String? ?? map['id'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      geofenceRadius: parseDouble(map['geofenceRadius']),
      status: parsedStatus,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Site &&
        other.siteId == siteId &&
        other.organizationId == organizationId &&
        other.name == name &&
        other.address == address &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.geofenceRadius == geofenceRadius &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      siteId,
      organizationId,
      name,
      address,
      latitude,
      longitude,
      geofenceRadius,
      status,
      createdAt,
      updatedAt,
    );
  }
}

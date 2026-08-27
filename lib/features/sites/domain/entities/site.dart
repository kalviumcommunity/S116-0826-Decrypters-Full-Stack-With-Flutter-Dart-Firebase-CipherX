import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class Site {
  final String id;
  final String organizationId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double geofenceRadius;
  final String qrToken;
  final int requiredGuardCount;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Site({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.address,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.geofenceRadius = 50.0,
    this.qrToken = '',
    this.requiredGuardCount = 1,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  Site copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? geofenceRadius,
    String? qrToken,
    int? requiredGuardCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Site(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geofenceRadius: geofenceRadius ?? this.geofenceRadius,
      qrToken: qrToken ?? this.qrToken,
      requiredGuardCount: requiredGuardCount ?? this.requiredGuardCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'siteId': id,
      'organizationId': organizationId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'geofenceRadius': geofenceRadius,
      'qrToken': qrToken,
      'requiredGuardCount': requiredGuardCount,
      'isActive': isActive,
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

    return Site(
      id: map['id'] as String? ?? map['siteId'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      geofenceRadius: (map['geofenceRadius'] as num?)?.toDouble() ?? 50.0,
      qrToken: map['qrToken'] as String? ?? '',
      requiredGuardCount: (map['requiredGuardCount'] as num?)?.toInt() ?? 1,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Site &&
        other.id == id &&
        other.organizationId == organizationId &&
        other.name == name &&
        other.address == address &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.geofenceRadius == geofenceRadius &&
        other.qrToken == qrToken &&
        other.requiredGuardCount == requiredGuardCount &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      organizationId,
      name,
      address,
      latitude,
      longitude,
      geofenceRadius,
      qrToken,
      requiredGuardCount,
      isActive,
      createdAt,
      updatedAt,
    );
  }
}

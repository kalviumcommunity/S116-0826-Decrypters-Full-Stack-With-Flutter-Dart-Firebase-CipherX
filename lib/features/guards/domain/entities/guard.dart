import 'package:flutter/foundation.dart';

enum GuardStatus {
  active,
  inactive;

  String toMapString() => name;

  static GuardStatus fromMapString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return GuardStatus.active;
      case 'inactive':
        return GuardStatus.inactive;
      default:
        throw FormatException('Invalid GuardStatus value: $value');
    }
  }
}

@immutable
class Guard {
  final String guardId;
  final String organizationId;
  final String name;
  final String employeeId;
  final String phone;
  final String? email;
  final String? photoUrl;
  final GuardStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Guard({
    required this.guardId,
    required this.organizationId,
    required this.name,
    required this.employeeId,
    required this.phone,
    this.email,
    this.photoUrl,
    this.status = GuardStatus.active,
    this.createdAt,
    this.updatedAt,
  });

  Guard copyWith({
    String? guardId,
    String? organizationId,
    String? name,
    String? employeeId,
    String? phone,
    String? email,
    String? photoUrl,
    GuardStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Guard(
      guardId: guardId ?? this.guardId,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      employeeId: employeeId ?? this.employeeId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'guardId': guardId,
      'organizationId': organizationId,
      'name': name,
      'employeeId': employeeId,
      'phone': phone,
      if (email != null) 'email': email,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'status': status.toMapString(),
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  factory Guard.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      try {
        return (val as dynamic).toDate();
      } catch (_) {
        return null;
      }
    }

    return Guard(
      guardId: map['guardId'] as String? ?? map['id'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String?,
      photoUrl: map['photoUrl'] as String? ?? map['profilePhotoUrl'] as String?,
      status: GuardStatus.fromMapString(map['status'] as String? ?? 'active'),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Guard &&
        other.guardId == guardId &&
        other.organizationId == organizationId &&
        other.name == name &&
        other.employeeId == employeeId &&
        other.phone == phone &&
        other.email == email &&
        other.photoUrl == photoUrl &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      guardId,
      organizationId,
      name,
      employeeId,
      phone,
      email,
      photoUrl,
      status,
      createdAt,
      updatedAt,
    );
  }
}

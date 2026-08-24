import 'package:flutter/foundation.dart';

enum UserStatus {
  active,
  inactive,
  suspended;

  String toMapString() => name;

  static UserStatus fromMapString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return UserStatus.active;
      case 'inactive':
        return UserStatus.inactive;
      case 'suspended':
        return UserStatus.suspended;
      default:
        return UserStatus.active;
    }
  }
}

enum UserRole {
  admin,
  supervisor,
  guard;

  String toMapString() => name;

  static UserRole fromMapString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'supervisor':
        return UserRole.supervisor;
      case 'guard':
        return UserRole.guard;
      default:
        return UserRole.guard;
    }
  }
}

@immutable
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String phone;
  final String organizationId;
  final UserStatus status;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phone,
    required this.organizationId,
    this.status = UserStatus.active,
    this.role = UserRole.guard,
    this.createdAt,
    this.updatedAt,
  });

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phone,
    String? organizationId,
    UserStatus? status,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      organizationId: organizationId ?? this.organizationId,
      status: status ?? this.status,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'organizationId': organizationId,
      'status': status.toMapString(),
      'role': role.toMapString(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
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

    return UserProfile(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      status: UserStatus.fromMapString(map['status'] as String? ?? 'active'),
      role: UserRole.fromMapString(map['role'] as String? ?? 'guard'),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.phone == phone &&
        other.organizationId == organizationId &&
        other.status == status &&
        other.role == role;
  }

  @override
  int get hashCode {
    return Object.hash(
      uid,
      email,
      displayName,
      phone,
      organizationId,
      status,
      role,
    );
  }
}

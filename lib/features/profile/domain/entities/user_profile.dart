import 'package:flutter/foundation.dart';
import '../../../../core/enums/user_role.dart';

@immutable
class UserProfile {
  final String uid;
  final UserRole? role;
  final String status;
  final String? organizationId;

  const UserProfile({
    required this.uid,
    this.role,
    this.status = 'inactive',
    this.organizationId,
  });

  bool get isActive => status.toLowerCase() == 'active';

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      uid: uid,
      role: UserRole.fromString(map['role'] as String?),
      status: map['status'] as String? ?? 'inactive',
      organizationId: map['organizationId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role?.toJson,
      'status': status,
      'organizationId': organizationId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.uid == uid &&
        other.role == role &&
        other.status == status &&
        other.organizationId == organizationId;
  }

  @override
  int get hashCode {
    return Object.hash(uid, role, status, organizationId);
  }

  @override
  String toString() {
    return 'UserProfile(uid: $uid, role: $role, status: $status, organizationId: $organizationId)';
  }
}

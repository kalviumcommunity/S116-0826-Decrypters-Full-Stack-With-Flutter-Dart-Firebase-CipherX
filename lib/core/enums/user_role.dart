enum UserRole {
  admin,
  supervisor,
  guard;

  static UserRole? fromString(String? roleString) {
    if (roleString == null) return null;
    switch (roleString.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'supervisor':
        return UserRole.supervisor;
      case 'guard':
        return UserRole.guard;
      default:
        return null;
    }
  }

  String get toJson => name;
}

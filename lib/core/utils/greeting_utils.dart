import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/identity/domain/entities/user_profile.dart';

/// Helper class providing personalized time-aware greetings and clean role formatting.
class GreetingUtils {
  GreetingUtils._();

  /// Returns a time-of-day greeting: 'Good morning', 'Good afternoon', or 'Good evening'.
  static String getTimeGreeting([DateTime? customTime]) {
    final hour = (customTime ?? DateTime.now()).hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  /// Extracts the user's first name from their profile or auth credentials.
  /// Falls back gracefully to the email prefix or a user-friendly role title.
  static String getFirstName({
    UserProfile? profile,
    AuthUser? authUser,
    String defaultFallback = 'User',
  }) {
    // 1. First check UserProfile displayName
    final profileName = profile?.displayName.trim();
    if (profileName != null && profileName.isNotEmpty) {
      final parts = profileName.split(RegExp(r'\s+'));
      if (parts.isNotEmpty && parts.first.isNotEmpty) {
        return parts.first;
      }
    }

    // 2. Fall back to AuthUser displayName
    final authName = authUser?.displayName?.trim();
    if (authName != null && authName.isNotEmpty) {
      final parts = authName.split(RegExp(r'\s+'));
      if (parts.isNotEmpty && parts.first.isNotEmpty) {
        return parts.first;
      }
    }

    // 3. Fall back to email prefix
    final email =
        (profile?.email.isNotEmpty == true ? profile?.email : authUser?.email)
            ?.trim();
    if (email != null && email.contains('@')) {
      final local = email.split('@').first.trim();
      if (local.isNotEmpty) {
        return local[0].toUpperCase() + local.substring(1);
      }
    }

    return defaultFallback;
  }

  /// Returns the human-readable professional title for a user role.
  static String getRoleTitle(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.guard:
        return 'Guard';
      case null:
        return 'User';
    }
  }
}

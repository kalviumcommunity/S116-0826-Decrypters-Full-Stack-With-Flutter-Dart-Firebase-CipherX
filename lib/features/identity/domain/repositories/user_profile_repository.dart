import '../entities/user_profile.dart';

abstract class UserProfileRepository {
  Future<UserProfile> createUserProfile(UserProfile profile);
  Future<UserProfile?> getUserProfile(String uid);
  Future<UserProfile> updateUserProfile({
    required String uid,
    String? displayName,
    String? phone,
  });
}

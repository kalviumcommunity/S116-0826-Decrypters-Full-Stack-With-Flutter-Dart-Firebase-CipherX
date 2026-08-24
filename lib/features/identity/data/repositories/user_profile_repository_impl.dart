import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/failures/identity_failure.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../domain/validators/user_profile_validator.dart';
import '../datasources/firebase_user_profile_data_source.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final FirebaseUserProfileDataSource _dataSource;

  UserProfileRepositoryImpl({
    required FirebaseUserProfileDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<UserProfile> createUserProfile(UserProfile profile) async {
    try {
      UserProfileValidator.validate(profile);
      await _dataSource.createUserProfile(profile);
      final fetched = await _dataSource.getUserProfile(profile.uid);
      return fetched ?? profile;
    } on IdentityFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownIdentityFailure(e.toString());
    }
  }

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      if (uid.trim().isEmpty) {
        throw const ProfileValidationFailure('UID cannot be empty.');
      }
      return await _dataSource.getUserProfile(uid);
    } on IdentityFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownIdentityFailure(e.toString());
    }
  }

  @override
  Future<UserProfile> updateUserProfile({
    required String uid,
    String? displayName,
    String? phone,
  }) async {
    try {
      if (uid.trim().isEmpty) {
        throw const ProfileValidationFailure('UID cannot be empty.');
      }
      if (displayName != null) {
        final err = UserProfileValidator.validateDisplayName(displayName);
        if (err != null) throw ProfileValidationFailure(err);
      }
      if (phone != null) {
        final err = UserProfileValidator.validatePhone(phone);
        if (err != null) throw ProfileValidationFailure(err);
      }

      return await _dataSource.updateUserProfile(
        uid: uid,
        displayName: displayName,
        phone: phone,
      );
    } on IdentityFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownIdentityFailure(e.toString());
    }
  }

  IdentityFailure _mapFirebaseException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const PermissionDeniedFailure();
      case 'not-found':
        return const ProfileNotFoundFailure();
      case 'unavailable':
        return const FirestoreFailure(
          'Database is temporarily unavailable. Check network connectivity.',
        );
      default:
        return FirestoreFailure(e.message ?? 'Firestore error occurred.');
    }
  }
}

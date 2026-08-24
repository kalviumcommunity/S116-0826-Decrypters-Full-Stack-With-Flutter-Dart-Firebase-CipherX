import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/firebase_organization_data_source.dart';
import '../../data/datasources/firebase_user_profile_data_source.dart';
import '../../data/repositories/organization_repository_impl.dart';
import '../../data/repositories/user_profile_repository_impl.dart';
import '../../domain/entities/organization.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/failures/identity_failure.dart';
import '../../domain/repositories/organization_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';

final cloudFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final userProfileDataSourceProvider =
    Provider<FirebaseUserProfileDataSource>((ref) {
  final firestore = ref.watch(cloudFirestoreProvider);
  return FirebaseUserProfileDataSource(firestore: firestore);
});

final organizationDataSourceProvider =
    Provider<FirebaseOrganizationDataSource>((ref) {
  final firestore = ref.watch(cloudFirestoreProvider);
  return FirebaseOrganizationDataSource(firestore: firestore);
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final dataSource = ref.watch(userProfileDataSourceProvider);
  return UserProfileRepositoryImpl(dataSource: dataSource);
});

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  final dataSource = ref.watch(organizationDataSourceProvider);
  return OrganizationRepositoryImpl(dataSource: dataSource);
});

final userProfileProvider =
    FutureProvider.family<UserProfile?, String>((ref, uid) async {
  final repository = ref.watch(userProfileRepositoryProvider);
  return await repository.getUserProfile(uid);
});

final organizationProvider =
    FutureProvider.family<Organization?, String>((ref, id) async {
  final repository = ref.watch(organizationRepositoryProvider);
  return await repository.getOrganizationById(id);
});

class ProfileController extends StateNotifier<AsyncValue<UserProfile?>> {
  final UserProfileRepository _userProfileRepository;
  final OrganizationRepository _organizationRepository;

  ProfileController({
    required UserProfileRepository userProfileRepository,
    required OrganizationRepository organizationRepository,
  })  : _userProfileRepository = userProfileRepository,
        _organizationRepository = organizationRepository,
        super(const AsyncValue.data(null));

  Future<UserProfile?> fetchProfile(String uid) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _userProfileRepository.getUserProfile(uid);
      state = AsyncValue.data(profile);
      return profile;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> createProfile({
    required String uid,
    required String email,
    required String displayName,
    required String phone,
    required String organizationCode,
  }) async {
    state = const AsyncValue.loading();
    try {
      final org =
          await _organizationRepository.getOrganizationByCode(organizationCode);
      if (org == null) {
        throw const OrganizationNotFoundFailure(
          'No organization found with this code. Please check code and try again.',
        );
      }

      final newProfile = UserProfile(
        uid: uid,
        email: email,
        displayName: displayName,
        phone: phone,
        organizationId: org.id,
        status: UserStatus.active,
        role: UserRole.guard,
      );

      final created =
          await _userProfileRepository.createUserProfile(newProfile);
      state = AsyncValue.data(created);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateProfile({
    required String uid,
    String? displayName,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _userProfileRepository.updateUserProfile(
        uid: uid,
        displayName: displayName,
        phone: phone,
      );
      state = AsyncValue.data(updated);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<UserProfile?>>((ref) {
  return ProfileController(
    userProfileRepository: ref.watch(userProfileRepositoryProvider),
    organizationRepository: ref.watch(organizationRepositoryProvider),
  );
});

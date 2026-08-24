import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cipher_x/features/identity/data/datasources/firebase_user_profile_data_source.dart';
import 'package:cipher_x/features/identity/data/repositories/user_profile_repository_impl.dart';
import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';
import 'package:cipher_x/features/identity/domain/failures/identity_failure.dart';

class MockFirebaseUserProfileDataSource extends Mock
    implements FirebaseUserProfileDataSource {}

void main() {
  late MockFirebaseUserProfileDataSource mockDataSource;
  late UserProfileRepositoryImpl repository;

  const tProfile = UserProfile(
    uid: 'u123',
    email: 'guard@cipherx.com',
    displayName: 'Guard Alex',
    phone: '+1 555-0199',
    organizationId: 'org_001',
  );

  setUp(() {
    mockDataSource = MockFirebaseUserProfileDataSource();
    repository = UserProfileRepositoryImpl(dataSource: mockDataSource);
  });

  group('UserProfileRepositoryImpl Unit Tests', () {
    test('createUserProfile succeeds on valid profile', () async {
      when(() => mockDataSource.createUserProfile(tProfile))
          .thenAnswer((_) async {});
      when(() => mockDataSource.getUserProfile(tProfile.uid))
          .thenAnswer((_) async => tProfile);

      final result = await repository.createUserProfile(tProfile);

      expect(result, equals(tProfile));
      verify(() => mockDataSource.createUserProfile(tProfile)).called(1);
    });

    test('getUserProfile returns profile when found', () async {
      when(() => mockDataSource.getUserProfile('u123'))
          .thenAnswer((_) async => tProfile);

      final result = await repository.getUserProfile('u123');

      expect(result, equals(tProfile));
      verify(() => mockDataSource.getUserProfile('u123')).called(1);
    });

    test('getUserProfile returns null when not found', () async {
      when(() => mockDataSource.getUserProfile('unknown'))
          .thenAnswer((_) async => null);

      final result = await repository.getUserProfile('unknown');

      expect(result, isNull);
    });

    test(
        'updateUserProfile calls datasource update and returns updated profile',
        () async {
      const updatedProfile = UserProfile(
        uid: 'u123',
        email: 'guard@cipherx.com',
        displayName: 'Guard Alex Updated',
        phone: '+1 555-9999',
        organizationId: 'org_001',
      );

      when(() => mockDataSource.updateUserProfile(
            uid: 'u123',
            displayName: 'Guard Alex Updated',
            phone: '+1 555-9999',
          )).thenAnswer((_) async => updatedProfile);

      final result = await repository.updateUserProfile(
        uid: 'u123',
        displayName: 'Guard Alex Updated',
        phone: '+1 555-9999',
      );

      expect(result.displayName, 'Guard Alex Updated');
      verify(() => mockDataSource.updateUserProfile(
            uid: 'u123',
            displayName: 'Guard Alex Updated',
            phone: '+1 555-9999',
          )).called(1);
    });

    test('maps permission-denied FirebaseException to PermissionDeniedFailure',
        () async {
      when(() => mockDataSource.getUserProfile('u123')).thenThrow(
        FirebaseException(plugin: 'firestore', code: 'permission-denied'),
      );

      expect(
        () => repository.getUserProfile('u123'),
        throwsA(isA<PermissionDeniedFailure>()),
      );
    });
  });
}

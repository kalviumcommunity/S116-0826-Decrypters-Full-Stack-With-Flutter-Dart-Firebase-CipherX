import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cipher_x/features/auth/domain/entities/auth_user.dart';
import 'package:cipher_x/features/auth/presentation/providers/auth_providers.dart';
import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';
import 'package:cipher_x/features/identity/domain/repositories/organization_repository.dart';
import 'package:cipher_x/features/identity/domain/repositories/user_profile_repository.dart';
import 'package:cipher_x/features/identity/presentation/providers/identity_providers.dart';
import 'package:cipher_x/features/identity/presentation/screens/profile_screen.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

void main() {
  late MockUserProfileRepository mockProfileRepository;
  late MockOrganizationRepository mockOrgRepository;

  setUp(() {
    mockProfileRepository = MockUserProfileRepository();
    mockOrgRepository = MockOrganizationRepository();
  });

  Widget buildTestableWidget(AuthUser authUser, UserProfile profile) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(authUser)),
        userProfileProvider(authUser.uid).overrideWith((ref) => profile),
        userProfileRepositoryProvider.overrideWithValue(mockProfileRepository),
        organizationRepositoryProvider.overrideWithValue(mockOrgRepository),
        profileControllerProvider.overrideWith((ref) => ProfileController(
              userProfileRepository: mockProfileRepository,
              organizationRepository: mockOrgRepository,
            )),
      ],
      child: const MaterialApp(
        home: ProfileScreen(),
      ),
    );
  }

  group('ProfileScreen Widget Tests', () {
    testWidgets('renders profile data and security boundaries',
        (WidgetTester tester) async {
      const authUser = AuthUser(uid: 'u_screen_1', email: 'guard1@cipherx.com');
      const profile = UserProfile(
        uid: 'u_screen_1',
        email: 'guard1@cipherx.com',
        displayName: 'Guard Alex',
        phone: '+1 555-0199',
        organizationId: 'org_001',
        status: UserStatus.active,
        role: UserRole.guard,
      );

      await tester.pumpWidget(buildTestableWidget(authUser, profile));
      await tester.pumpAndSettle();

      expect(find.text('Guard Alex'), findsAtLeastNWidgets(1));
      expect(find.text('guard1@cipherx.com'), findsOneWidget);
      expect(find.text('User UID'), findsOneWidget);
      expect(find.text('u_screen_1'), findsOneWidget);
      expect(find.text('Organization ID'), findsOneWidget);
      expect(find.text('org_001'), findsOneWidget);
      expect(find.text('Assigned Identity Role'), findsOneWidget);
      expect(find.text('GUARD'), findsOneWidget);
    });

    testWidgets('toggles edit mode and enables fields',
        (WidgetTester tester) async {
      const authUser = AuthUser(uid: 'u_screen_2', email: 'guard2@cipherx.com');
      const profile = UserProfile(
        uid: 'u_screen_2',
        email: 'guard2@cipherx.com',
        displayName: 'Guard Bob',
        phone: '+1 555-0299',
        organizationId: 'org_001',
        status: UserStatus.active,
        role: UserRole.guard,
      );

      await tester.pumpWidget(buildTestableWidget(authUser, profile));
      await tester.pumpAndSettle();

      final editButton = find.byKey(const Key('enable_edit_profile_button'));
      expect(editButton, findsOneWidget);

      await tester.ensureVisible(editButton);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save_profile_button')), findsOneWidget);
    });
  });
}

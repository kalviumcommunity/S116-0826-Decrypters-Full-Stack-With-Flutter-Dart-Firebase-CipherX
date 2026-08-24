import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cipher_x/features/auth/domain/entities/auth_user.dart';
import 'package:cipher_x/features/auth/presentation/providers/auth_providers.dart';
import 'package:cipher_x/features/identity/domain/entities/organization.dart';
import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';
import 'package:cipher_x/features/identity/domain/repositories/organization_repository.dart';
import 'package:cipher_x/features/identity/domain/repositories/user_profile_repository.dart';
import 'package:cipher_x/features/identity/presentation/providers/identity_providers.dart';
import 'package:cipher_x/features/identity/presentation/screens/profile_setup_screen.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

void main() {
  late MockUserProfileRepository mockProfileRepository;
  late MockOrganizationRepository mockOrgRepository;

  const tAuthUser = AuthUser(uid: 'u123', email: 'newguard@cipherx.com');
  const tOrg = Organization(
    id: 'org_001',
    name: 'Apex Security Services',
    code: 'ORG001',
  );
  const tCreatedProfile = UserProfile(
    uid: 'u123',
    email: 'newguard@cipherx.com',
    displayName: 'Guard Alex',
    phone: '+1 555-0199',
    organizationId: 'org_001',
  );

  setUpAll(() {
    registerFallbackValue(tCreatedProfile);
  });

  setUp(() {
    mockProfileRepository = MockUserProfileRepository();
    mockOrgRepository = MockOrganizationRepository();
  });

  Widget buildTestableWidget() {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(tAuthUser)),
        userProfileRepositoryProvider.overrideWithValue(mockProfileRepository),
        organizationRepositoryProvider.overrideWithValue(mockOrgRepository),
      ],
      child: const MaterialApp(
        home: ProfileSetupScreen(),
      ),
    );
  }

  group('ProfileSetupScreen Widget Tests', () {
    testWidgets('renders all ProfileSetupScreen fields and controls',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('User Profile Setup'), findsOneWidget);
      expect(find.byKey(const Key('displayName_field')), findsOneWidget);
      expect(find.byKey(const Key('phone_field')), findsOneWidget);
      expect(find.byKey(const Key('organization_code_field')), findsOneWidget);
      expect(
          find.byKey(const Key('setup_profile_submit_button')), findsOneWidget);
    });

    testWidgets('shows validation errors when submitted empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('setup_profile_submit_button')));
      await tester.pump();

      expect(find.text('Display name is required.'), findsOneWidget);
      expect(find.text('Phone number is required.'), findsOneWidget);
      expect(find.text('Organization code is required.'), findsOneWidget);
      verifyNever(() => mockOrgRepository.getOrganizationByCode(any()));
    });

    testWidgets('submits profile setup successfully when input is valid',
        (WidgetTester tester) async {
      when(() => mockOrgRepository.getOrganizationByCode('ORG001'))
          .thenAnswer((_) async => tOrg);
      when(() => mockProfileRepository.createUserProfile(any()))
          .thenAnswer((_) async => tCreatedProfile);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('displayName_field')),
        'Guard Alex',
      );
      await tester.enterText(
        find.byKey(const Key('phone_field')),
        '+1 555-0199',
      );
      await tester.enterText(
        find.byKey(const Key('organization_code_field')),
        'ORG001',
      );

      await tester.tap(find.byKey(const Key('setup_profile_submit_button')));
      await tester.pumpAndSettle();

      verify(() => mockOrgRepository.getOrganizationByCode('ORG001')).called(1);
    });
  });
}

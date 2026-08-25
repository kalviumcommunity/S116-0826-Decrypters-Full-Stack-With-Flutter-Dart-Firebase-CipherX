import 'package:cipher_x/app/router/app_router.dart';
import 'package:cipher_x/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:cipher_x/features/auth/domain/entities/auth_user.dart';
import 'package:cipher_x/features/auth/domain/repositories/auth_repository.dart';
import 'package:cipher_x/features/auth/presentation/providers/auth_providers.dart';
import 'package:cipher_x/features/auth/presentation/screens/access_denied_screen.dart';
import 'package:cipher_x/features/auth/presentation/screens/login_screen.dart';
import 'package:cipher_x/features/guard/presentation/screens/guard_home_screen.dart';
import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';
import 'package:cipher_x/features/identity/domain/repositories/organization_repository.dart';
import 'package:cipher_x/features/identity/domain/repositories/user_profile_repository.dart';
import 'package:cipher_x/features/identity/presentation/providers/identity_providers.dart';
import 'package:cipher_x/features/identity/presentation/screens/profile_setup_screen.dart';
import 'package:cipher_x/features/supervisor/presentation/screens/supervisor_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockUserProfileRepository mockUserProfileRepository;
  late MockOrganizationRepository mockOrganizationRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockUserProfileRepository = MockUserProfileRepository();
    mockOrganizationRepository = MockOrganizationRepository();
  });

  group('Router Redirect Logic', () {
    testWidgets('Unauthenticated user is redirected to /login', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          userProfileRepositoryProvider
              .overrideWithValue(mockUserProfileRepository),
          organizationRepositoryProvider
              .overrideWithValue(mockOrganizationRepository),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          currentUserProfileProvider.overrideWithValue(
            const AsyncValue.data(null),
          ),
        ],
      );

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets(
      'Authenticated user without profile is redirected to /profile-setup',
      (WidgetTester tester) async {
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
            userProfileRepositoryProvider
                .overrideWithValue(mockUserProfileRepository),
            organizationRepositoryProvider
                .overrideWithValue(mockOrganizationRepository),
            authStateProvider.overrideWith(
              (ref) => Stream.value(
                const AuthUser(uid: 'new_uid', email: 'new@test.com'),
              ),
            ),
            currentUserProfileProvider.overrideWithValue(
              const AsyncValue.data(null),
            ),
          ],
        );

        final router = container.read(appRouterProvider);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(ProfileSetupScreen), findsOneWidget);
      },
    );

    testWidgets('Admin user is redirected to /admin/dashboard', (
      WidgetTester tester,
    ) async {
      const adminProfile = UserProfile(
        uid: 'admin_uid',
        email: 'admin@test.com',
        displayName: 'Admin User',
        phone: '+1234567890',
        organizationId: 'org123',
        role: UserRole.admin,
        status: UserStatus.active,
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          userProfileRepositoryProvider
              .overrideWithValue(mockUserProfileRepository),
          organizationRepositoryProvider
              .overrideWithValue(mockOrganizationRepository),
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(uid: 'admin_uid', email: 'admin@test.com'),
            ),
          ),
          currentUserProfileProvider.overrideWithValue(
            const AsyncValue.data(adminProfile),
          ),
        ],
      );

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
    });

    testWidgets('Supervisor user is redirected to /supervisor/dashboard', (
      WidgetTester tester,
    ) async {
      const superProfile = UserProfile(
        uid: 'super_uid',
        email: 'super@test.com',
        displayName: 'Supervisor User',
        phone: '+1234567890',
        organizationId: 'org123',
        role: UserRole.supervisor,
        status: UserStatus.active,
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          userProfileRepositoryProvider
              .overrideWithValue(mockUserProfileRepository),
          organizationRepositoryProvider
              .overrideWithValue(mockOrganizationRepository),
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(uid: 'super_uid', email: 'super@test.com'),
            ),
          ),
          currentUserProfileProvider.overrideWithValue(
            const AsyncValue.data(superProfile),
          ),
        ],
      );

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SupervisorDashboardScreen), findsOneWidget);
    });

    testWidgets('Guard user is redirected to /guard/home', (
      WidgetTester tester,
    ) async {
      const guardProfile = UserProfile(
        uid: 'guard_uid',
        email: 'guard@test.com',
        displayName: 'Guard User',
        phone: '+1234567890',
        organizationId: 'org123',
        role: UserRole.guard,
        status: UserStatus.active,
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          userProfileRepositoryProvider
              .overrideWithValue(mockUserProfileRepository),
          organizationRepositoryProvider
              .overrideWithValue(mockOrganizationRepository),
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(uid: 'guard_uid', email: 'guard@test.com'),
            ),
          ),
          currentUserProfileProvider.overrideWithValue(
            const AsyncValue.data(guardProfile),
          ),
        ],
      );

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(GuardHomeScreen), findsOneWidget);
    });

    testWidgets('Inactive user is redirected to /access-denied', (
      WidgetTester tester,
    ) async {
      const inactiveProfile = UserProfile(
        uid: 'inactive_uid',
        email: 'inactive@test.com',
        displayName: 'Inactive User',
        phone: '+1234567890',
        organizationId: 'org123',
        role: UserRole.guard,
        status: UserStatus.inactive,
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          userProfileRepositoryProvider
              .overrideWithValue(mockUserProfileRepository),
          organizationRepositoryProvider
              .overrideWithValue(mockOrganizationRepository),
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(uid: 'inactive_uid', email: 'inactive@test.com'),
            ),
          ),
          currentUserProfileProvider.overrideWithValue(
            const AsyncValue.data(inactiveProfile),
          ),
        ],
      );

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AccessDeniedScreen), findsOneWidget);
    });
  });
}

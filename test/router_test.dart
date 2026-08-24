import 'package:cipher_x/app/router/app_router.dart';
import 'package:cipher_x/core/enums/user_role.dart';
import 'package:cipher_x/features/auth/domain/entities/auth_user.dart';
import 'package:cipher_x/features/auth/presentation/providers/auth_providers.dart';
import 'package:cipher_x/features/profile/domain/entities/user_profile.dart';
import 'package:cipher_x/features/profile/presentation/providers/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Router Redirect Logic', () {
    testWidgets('Unauthenticated user is redirected to /login', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          userProfileProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
    });

    testWidgets('Admin user is redirected to /admin/dashboard', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(uid: 'admin_uid', email: 'admin@test.com'),
            ),
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(
              const UserProfile(
                uid: 'admin_uid',
                role: UserRole.admin,
                status: 'active',
              ),
            ),
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
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/admin/dashboard',
      );
    });

    testWidgets('Supervisor user is redirected to /supervisor/dashboard', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(uid: 'super_uid', email: 'super@test.com'),
            ),
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(
              const UserProfile(
                uid: 'super_uid',
                role: UserRole.supervisor,
                status: 'active',
              ),
            ),
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
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/supervisor/dashboard',
      );
    });

    testWidgets('Guard user is redirected to /guard/home', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(uid: 'guard_uid', email: 'guard@test.com'),
            ),
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(
              const UserProfile(
                uid: 'guard_uid',
                role: UserRole.guard,
                status: 'active',
              ),
            ),
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
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/guard/home',
      );
    });

    testWidgets('Inactive user is redirected to /access-denied', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(uid: 'inactive_uid', email: 'inactive@test.com'),
            ),
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(
              const UserProfile(
                uid: 'inactive_uid',
                role: UserRole.admin,
                status: 'inactive',
              ),
            ),
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
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/access-denied',
      );
    });
  });
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';
import 'package:cipher_x/features/identity/presentation/providers/identity_providers.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';
import 'package:cipher_x/features/sites/presentation/providers/site_providers.dart';
import 'package:cipher_x/features/sites/presentation/screens/site_list_screen.dart';

void main() {
  const tProfile = UserProfile(
    uid: 'user-100',
    email: 'admin@cipherx.com',
    displayName: 'Admin User',
    phone: '+1 555-0100',
    role: UserRole.admin,
    organizationId: 'org-100',
  );

  const tSite1 = Site(
    siteId: 'site-001',
    organizationId: 'org-100',
    name: 'HQ Campus',
    address: '123 Tech Park, Tower A',
    latitude: 18.5204,
    longitude: 73.8567,
    geofenceRadius: 500.0,
    status: SiteStatus.active,
  );

  const tSite2 = Site(
    siteId: 'site-002',
    organizationId: 'org-100',
    name: 'Warehouse South',
    address: '456 Industrial Belt',
    latitude: 18.4000,
    longitude: 73.9000,
    geofenceRadius: 750.0,
    status: SiteStatus.inactive,
  );

  group('SiteListScreen Widget Tests', () {
    testWidgets('displays loading indicator when sites are loading',
        (tester) async {
      final completer = Completer<List<Site>>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith(
              (ref) => const AsyncData(tProfile),
            ),
            sitesListProvider(false).overrideWith((ref) => completer.future),
          ],
          child: const MaterialApp(
            home: SiteListScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays empty state when site list is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith(
              (ref) => const AsyncData(tProfile),
            ),
            sitesListProvider(false).overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: SiteListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No sites yet'), findsOneWidget);
      expect(find.text('Create Site'), findsWidgets);
    });

    testWidgets('renders site cards with coordinates and status badges',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith(
              (ref) => const AsyncData(tProfile),
            ),
            sitesListProvider(false)
                .overrideWith((ref) async => [tSite1, tSite2]),
          ],
          child: const MaterialApp(
            home: SiteListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('HQ Campus'), findsOneWidget);
      expect(find.text('123 Tech Park, Tower A'), findsOneWidget);
      expect(find.text('18.5204, 73.8567'), findsOneWidget);
      expect(find.text('500 meters'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      expect(find.text('Warehouse South'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
    });

    testWidgets('filters sites by search query', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith(
              (ref) => const AsyncData(tProfile),
            ),
            sitesListProvider(false)
                .overrideWith((ref) async => [tSite1, tSite2]),
          ],
          child: const MaterialApp(
            home: SiteListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Warehouse');
      await tester.pumpAndSettle();

      expect(find.text('Warehouse South'), findsOneWidget);
      expect(find.text('HQ Campus'), findsNothing);
    });

    testWidgets('displays error UI and retry button when loading fails',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith(
              (ref) => const AsyncData(tProfile),
            ),
            sitesListProvider(false)
                .overrideWith((ref) async => throw Exception('Network error')),
          ],
          child: const MaterialApp(
            home: SiteListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load sites'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}

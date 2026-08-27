import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';
import 'package:cipher_x/features/identity/presentation/providers/identity_providers.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';
import 'package:cipher_x/features/sites/presentation/screens/site_form_screen.dart';

void main() {
  const tProfile = UserProfile(
    uid: 'user-100',
    email: 'admin@cipherx.com',
    displayName: 'Admin User',
    role: UserRole.admin,
    phone: '+1 555-0100',
    organizationId: 'org-100',
  );

  const tExistingSite = Site(
    siteId: 'site-001',
    organizationId: 'org-100',
    name: 'Existing HQ',
    address: '100 Security Blvd',
    latitude: 20.0,
    longitude: 75.0,
    geofenceRadius: 400.0,
    status: SiteStatus.active,
  );

  group('SiteFormScreen Widget Tests', () {
    testWidgets('renders all form fields in Create Mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith(
              (ref) => const AsyncData(tProfile),
            ),
          ],
          child: const MaterialApp(
            home: SiteFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Create Site'), findsWidgets);
      expect(find.widgetWithText(TextFormField, 'Site Name *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Address *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Latitude *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Longitude *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Geofence Radius *'),
          findsOneWidget);
    });

    testWidgets('populates existing site data in Edit Mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith(
              (ref) => const AsyncData(tProfile),
            ),
          ],
          child: const MaterialApp(
            home: SiteFormScreen(existingSite: tExistingSite),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Site'), findsWidgets);
      expect(find.text('Existing HQ'), findsOneWidget);
      expect(find.text('100 Security Blvd'), findsOneWidget);
      expect(find.text('20.0'), findsOneWidget);
      expect(find.text('75.0'), findsOneWidget);
      expect(find.text('400.0'), findsOneWidget);
      expect(find.text('Site Status'), findsOneWidget);
    });

    testWidgets(
        'shows validation errors for out-of-range coordinates and radius',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith(
              (ref) => const AsyncData(tProfile),
            ),
          ],
          child: const MaterialApp(
            home: SiteFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter invalid latitude (> 90)
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Latitude *'),
        '100.0',
      );

      // Enter invalid longitude (< -180)
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Longitude *'),
        '-200.0',
      );

      // Enter invalid radius (<= 0)
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Geofence Radius *'),
        '-50.0',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Site'));
      await tester.pumpAndSettle();

      expect(find.text('Latitude must be between -90 and 90 degrees.'),
          findsOneWidget);
      expect(find.text('Longitude must be between -180 and 180 degrees.'),
          findsOneWidget);
      expect(find.text('Geofence radius must be greater than 0 meters.'),
          findsOneWidget);
    });
  });
}

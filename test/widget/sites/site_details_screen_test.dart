import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';
import 'package:cipher_x/features/sites/presentation/screens/site_details_screen.dart';

void main() {
  final tDate = DateTime(2026, 8, 25, 10, 30);
  final tSite = Site(
    siteId: 'site-999',
    organizationId: 'org-100',
    name: 'Metropolis Guard Post',
    address: '777 Hero Lane',
    latitude: 40.7128,
    longitude: -74.0060,
    geofenceRadius: 600.0,
    status: SiteStatus.active,
    createdAt: tDate,
    updatedAt: tDate,
  );

  group('SiteDetailsScreen Widget Tests', () {
    testWidgets('renders all site details and explicit radius unit',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: SiteDetailsScreen(site: tSite),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Metropolis Guard Post'), findsWidgets);
      expect(find.text('777 Hero Lane'), findsOneWidget);
      expect(find.text('40.7128'), findsOneWidget);
      expect(find.text('-74.006'), findsOneWidget);
      expect(find.text('600.0 meters'), findsOneWidget);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Edit Site'), findsWidgets);
      expect(find.text('Deactivate'), findsOneWidget);
    });

    testWidgets('shows confirmation dialog on deactivation tap',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: SiteDetailsScreen(site: tSite),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final deactivateBtn = find.text('Deactivate');
      await tester.ensureVisible(deactivateBtn);
      await tester.tap(deactivateBtn);
      await tester.pumpAndSettle();

      expect(find.text('Deactivate Site?'), findsOneWidget);
      expect(
        find.text(
          'This site will no longer be treated as active. Operational records will be preserved.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cipher_x/features/admin/domain/entities/coverage_status.dart';
import 'package:cipher_x/features/admin/domain/entities/dashboard_statistics.dart';
import 'package:cipher_x/features/admin/domain/entities/site_coverage_filter.dart';
import 'package:cipher_x/features/admin/domain/entities/site_coverage_item.dart';
import 'package:cipher_x/features/admin/presentation/providers/admin_dashboard_providers.dart';
import 'package:cipher_x/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:cipher_x/features/admin/presentation/widgets/metric_card.dart';
import 'package:cipher_x/features/admin/presentation/widgets/site_coverage_filter_bar.dart';
import 'package:cipher_x/features/admin/presentation/widgets/site_coverage_item_card.dart';
import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';
import 'package:cipher_x/features/identity/presentation/providers/identity_providers.dart';

void main() {
  group('MetricCard Widget Tests', () {
    testWidgets('renders title, value, subtitle, and triggers onTap callback',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetricCard(
              title: 'On Duty',
              value: '14',
              icon: Icons.verified_user,
              color: Colors.green,
              subtitle: 'Active Shifts',
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('On Duty'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('Active Shifts'), findsOneWidget);
      expect(find.byIcon(Icons.verified_user), findsOneWidget);

      await tester.tap(find.byType(MetricCard));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('SiteCoverageFilterBar Widget Tests', () {
    testWidgets('renders all chips and triggers filter selection',
        (tester) async {
      SiteCoverageFilter? selectedFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SiteCoverageFilterBar(
              currentFilter: SiteCoverageFilter.all,
              onFilterChanged: (filter) {
                selectedFilter = filter;
              },
            ),
          ),
        ),
      );

      expect(find.text('All Sites'), findsOneWidget);
      expect(find.text('Fully Staffed'), findsOneWidget);
      expect(find.text('Understaffed'), findsOneWidget);

      await tester.tap(find.byKey(const Key('filter_chip_understaffed')));
      await tester.pumpAndSettle();

      expect(selectedFilter, SiteCoverageFilter.understaffed);
    });
  });

  group('SiteCoverageItemCard Widget Tests', () {
    testWidgets('renders fully staffed site with green badge', (tester) async {
      const item = SiteCoverageItem(
        siteId: 'site_101',
        siteName: 'Central Plaza',
        organizationId: 'org_test',
        actualStaff: 4,
        requiredStaff: 4,
        status: CoverageStatus.fullyStaffed,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SiteCoverageItemCard(item: item),
          ),
        ),
      );

      expect(find.text('Central Plaza'), findsOneWidget);
      expect(find.text('Staffing: 4 / 4 Guards'), findsOneWidget);
      expect(find.text('FULLY STAFFED'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('renders understaffed site with red badge and deficit',
        (tester) async {
      const item = SiteCoverageItem(
        siteId: 'site_102',
        siteName: 'West Terminal',
        organizationId: 'org_test',
        actualStaff: 1,
        requiredStaff: 3,
        status: CoverageStatus.understaffed,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SiteCoverageItemCard(item: item),
          ),
        ),
      );

      expect(find.text('West Terminal'), findsOneWidget);
      expect(find.text('Staffing: 1 / 3 Guards'), findsOneWidget);
      expect(find.text('UNDERSTAFFED'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });

  group('AdminDashboardScreen Command Center Integration Tests', () {
    const adminProfile = UserProfile(
      uid: 'admin_123',
      email: 'admin@cipherx.com',
      displayName: 'Captain Jack',
      phone: '+1234567890',
      organizationId: 'org_omega',
      role: UserRole.admin,
    );

    const testStats = DashboardStatistics(
      totalGuards: 16,
      onDutyGuards: 10,
      absentGuards: 2,
      lateGuards: 1,
      activeSites: 6,
      openIncidents: 3,
      criticalAlerts: 1,
    );

    const testCoverage = [
      SiteCoverageItem(
        siteId: 'site_alpha',
        siteName: 'Alpha Base',
        organizationId: 'org_omega',
        actualStaff: 5,
        requiredStaff: 5,
        status: CoverageStatus.fullyStaffed,
      ),
      SiteCoverageItem(
        siteId: 'site_beta',
        siteName: 'Beta Outpost',
        organizationId: 'org_omega',
        actualStaff: 2,
        requiredStaff: 4,
        status: CoverageStatus.understaffed,
      ),
    ];

    testWidgets(
        'renders command center with all KPI metric cards and site coverage items',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWithValue(
              const AsyncData(adminProfile),
            ),
            dashboardStatisticsStreamProvider.overrideWith(
              (ref) => Stream.value(testStats),
            ),
            siteCoverageStreamProvider.overrideWith(
              (ref) => Stream.value(testCoverage),
            ),
          ],
          child: const MaterialApp(
            home: AdminDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Command Center'), findsOneWidget);
      expect(find.textContaining('Captain'), findsOneWidget);
      expect(find.text('Administrator'), findsOneWidget);
      expect(find.text('Organization: org_omega'), findsOneWidget);

      // Verify KPI Section
      expect(find.text('Operations Overview'), findsOneWidget);
      expect(find.text('Total Guards'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.text('On Duty'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Late'), findsOneWidget);
      expect(
          find.text('1'), findsNWidgets(2)); // Late is 1, Critical Alerts is 1
      expect(find.text('Active Sites'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('Open Incidents'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Critical Alerts'), findsOneWidget);

      // Verify Site Staffing Coverage Section
      expect(find.text('Site Staffing Coverage'), findsOneWidget);
      expect(find.text('Alpha Base'), findsOneWidget);
      expect(find.text('Beta Outpost'), findsOneWidget);
      expect(find.text('FULLY STAFFED'), findsOneWidget);
      expect(find.text('UNDERSTAFFED'), findsOneWidget);

      // Verify Navigation Shortcut Buttons
      expect(find.text('Guards'), findsOneWidget);
      expect(find.text('Sites'), findsOneWidget);
      expect(find.text('Incidents'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/alerts/domain/entities/alert.dart';
import 'package:cipher_x/features/alerts/domain/entities/alert_status.dart';
import 'package:cipher_x/features/alerts/domain/entities/alert_type.dart';
import 'package:cipher_x/features/activity/domain/entities/audit_log.dart';
import 'package:cipher_x/features/activity/presentation/providers/activity_feed_providers.dart';
import 'package:cipher_x/features/activity/presentation/screens/alerts_activity_feed_screen.dart';
import 'package:cipher_x/features/attendance/domain/entities/attendance_record.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident.dart';

void main() {
  group('AlertsActivityFeedScreen Widget Tests', () {
    testWidgets('renders all 4 tabs and displays empty state on Alerts tab',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recentAlertsFeedProvider
                .overrideWith((ref) => Stream.value(<Alert>[])),
            recentIncidentsFeedProvider
                .overrideWith((ref) => Stream.value(<Incident>[])),
            recentAttendanceFeedProvider
                .overrideWith((ref) => Stream.value(<AttendanceRecord>[])),
            recentAuditActivityProvider
                .overrideWith((ref) => Stream.value(<AuditLog>[])),
          ],
          child: const MaterialApp(
            home: AlertsActivityFeedScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Alerts & Activity Feed'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('Incidents'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Activity Audit'), findsOneWidget);

      expect(find.text('No Recent Operational Alerts'), findsOneWidget);
    });

    testWidgets('renders alert card when recentAlertsFeedProvider has data',
        (tester) async {
      final sampleAlert = Alert(
        alertId: 'alt_test_01',
        organizationId: 'org_001',
        type: AlertType.understaffedSite,
        sourceEntityId: 'site_bravo',
        sourceEntityType: 'site',
        createdAt: DateTime.utc(2026, 9, 17, 10, 0),
        status: AlertStatus.active,
        metadata: const {
          'message': 'Site Bravo requires 4 guards, only 2 on duty.',
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recentAlertsFeedProvider
                .overrideWith((ref) => Stream.value([sampleAlert])),
            recentIncidentsFeedProvider
                .overrideWith((ref) => Stream.value(<Incident>[])),
            recentAttendanceFeedProvider
                .overrideWith((ref) => Stream.value(<AttendanceRecord>[])),
            recentAuditActivityProvider
                .overrideWith((ref) => Stream.value(<AuditLog>[])),
          ],
          child: const MaterialApp(
            home: AlertsActivityFeedScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Understaffed Site'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);
      expect(find.text('Site Bravo requires 4 guards, only 2 on duty.'),
          findsOneWidget);
    });
  });
}

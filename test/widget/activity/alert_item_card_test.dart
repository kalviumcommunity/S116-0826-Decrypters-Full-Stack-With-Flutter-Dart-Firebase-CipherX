import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/alerts/domain/entities/alert.dart';
import 'package:cipher_x/features/alerts/domain/entities/alert_status.dart';
import 'package:cipher_x/features/alerts/domain/entities/alert_type.dart';
import 'package:cipher_x/features/activity/presentation/widgets/alert_item_card.dart';

void main() {
  group('AlertItemCard Widget Tests', () {
    testWidgets('renders Critical Incident alert details accurately',
        (tester) async {
      final alert = Alert(
        alertId: 'alt_crit_01',
        organizationId: 'org_001',
        type: AlertType.criticalIncident,
        sourceEntityId: 'inc_901',
        sourceEntityType: 'incident',
        createdAt: DateTime.utc(2026, 9, 17, 9, 15),
        status: AlertStatus.active,
        metadata: const {
          'siteId': 'site_delta',
          'message': 'Perimeter breach reported by guard EMP-101.',
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlertItemCard(alert: alert),
          ),
        ),
      );

      expect(find.text('Critical Incident'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.text('Perimeter breach reported by guard EMP-101.'),
          findsOneWidget);
      expect(find.text('Site: site_delta'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('renders Late Check-In alert details accurately',
        (tester) async {
      final alert = Alert(
        alertId: 'alt_late_02',
        organizationId: 'org_001',
        type: AlertType.lateCheckIn,
        sourceEntityId: 'shift_404',
        sourceEntityType: 'shift',
        createdAt: DateTime.utc(2026, 9, 17, 8, 30),
        status: AlertStatus.resolved,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlertItemCard(alert: alert),
          ),
        ),
      );

      expect(find.text('Late Check-In'), findsOneWidget);
      expect(find.text('NOTICE'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
    });
  });
}

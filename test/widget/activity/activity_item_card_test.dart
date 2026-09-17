import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/activity/domain/entities/audit_log.dart';
import 'package:cipher_x/features/activity/presentation/widgets/activity_item_card.dart';

void main() {
  group('ActivityItemCard Widget Tests', () {
    testWidgets('renders AuditLog entry details accurately', (tester) async {
      final auditLog = AuditLog(
        id: 'aud_909',
        organizationId: 'org_001',
        actorId: 'usr_admin',
        actorName: 'Hardik Admin',
        actorRole: 'admin',
        action: 'CHECK_IN_SUCCESS',
        entityType: 'attendance',
        entityId: 'att_777',
        timestamp: DateTime.utc(2026, 9, 17, 10, 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityItemCard(auditLog: auditLog),
          ),
        ),
      );

      expect(find.text('Hardik Admin'), findsOneWidget);
      expect(find.text('ADMIN'), findsOneWidget);
      expect(find.text('CHECK IN SUCCESS'), findsOneWidget);
      expect(find.text('Target: ATTENDANCE'), findsOneWidget);
    });
  });
}

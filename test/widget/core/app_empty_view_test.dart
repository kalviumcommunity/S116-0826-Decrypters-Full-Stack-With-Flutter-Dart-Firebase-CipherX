import 'package:cipher_x/core/widgets/app_empty_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEmptyView Widget Tests', () {
    testWidgets('renders title and message with default icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppEmptyView(
              title: 'No Shifts Found',
              message: 'You have no scheduled shifts at this time.',
            ),
          ),
        ),
      );

      expect(find.text('No Shifts Found'), findsOneWidget);
      expect(find.text('You have no scheduled shifts at this time.'),
          findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets(
        'renders custom icon, action button and fires onAction callback',
        (tester) async {
      var actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyView(
              title: 'No Incidents',
              message: 'No open incidents reported.',
              icon: Icons.shield_outlined,
              actionLabel: 'Refresh Feed',
              onAction: () {
                actionTriggered = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('No Incidents'), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      expect(find.text('Refresh Feed'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(actionTriggered, isTrue);
    });
  });
}

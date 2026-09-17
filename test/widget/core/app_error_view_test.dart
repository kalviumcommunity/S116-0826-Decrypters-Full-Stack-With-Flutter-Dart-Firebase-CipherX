import 'package:cipher_x/core/widgets/app_error_view.dart';
import 'package:cipher_x/features/attendance/domain/failures/attendance_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppErrorView Widget Tests', () {
    testWidgets('renders title and message correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppErrorView(
              title: 'Connection Error',
              message: 'Could not connect to the server.',
            ),
          ),
        ),
      );

      expect(find.text('Connection Error'), findsOneWidget);
      expect(find.text('Could not connect to the server.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets(
        'fromError factory extracts message via FailureMapper and handles retry',
        (tester) async {
      var retryTriggered = false;
      const failure = AttendanceNotFoundFailure();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorView.fromError(
              error: failure,
              onRetry: () {
                retryTriggered = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Error'), findsOneWidget);
      expect(find.text(failure.message), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(retryTriggered, isTrue);
    });
  });
}

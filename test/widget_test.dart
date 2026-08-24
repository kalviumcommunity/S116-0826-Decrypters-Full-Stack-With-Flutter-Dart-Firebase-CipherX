import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cipher_x/app/app.dart';
import 'package:cipher_x/app/theme/app_theme.dart';
import 'package:cipher_x/core/config/app_config.dart';
import 'package:cipher_x/core/services/firebase_service.dart';
import 'package:cipher_x/core/widgets/app_error_view.dart';
import 'package:cipher_x/core/widgets/app_loading.dart';

void main() {
  group('Cipher-X Bootstrap & Firebase Foundation Tests', () {
    testWidgets(
      'Root CipherXApp navigates to NavigationShell and renders Home',
      (WidgetTester tester) async {
        await tester.pumpWidget(const ProviderScope(child: CipherXApp()));

        // Initially, splash screen elements should be visible
        expect(find.byIcon(Icons.shield_outlined), findsOneWidget);

        // Let the navigation delay complete
        await tester.pumpAndSettle();

        // Should now be on the Shift tab of NavigationShell
        expect(find.text('Placeholder for Shift'), findsOneWidget);
      },
    );

    test(
      'AppTheme light and dark modes configure correct brightness & Material 3',
      () {
        final ThemeData light = AppTheme.lightTheme;
        final ThemeData dark = AppTheme.darkTheme;

        expect(light.useMaterial3, isTrue);
        expect(light.brightness, equals(Brightness.light));

        expect(dark.useMaterial3, isTrue);
        expect(dark.brightness, equals(Brightness.dark));
      },
    );

    test('AppConfig resolves environment dynamically', () {
      final AppConfig defaultDevConfig = AppConfig.fromEnvironment();
      expect(defaultDevConfig.environment, equals(AppEnvironment.development));
      expect(defaultDevConfig.enableLogging, isTrue);
    });

    test('FirebaseService exposes correct emulator ports & checkHealth diagnostics', () {
      expect(FirebaseService.authEmulatorPort, equals(9099));
      expect(FirebaseService.firestoreEmulatorPort, equals(8080));
      expect(FirebaseService.storageEmulatorPort, equals(9199));
      expect(FirebaseService.emulatorHostLocalhost, equals('localhost'));
      expect(FirebaseService.emulatorHostAndroid, equals('10.0.2.2'));

      final Map<String, dynamic> health = FirebaseService.checkHealth();
      expect(health['authAvailable'], isTrue);
      expect(health['firestoreAvailable'], isTrue);
      expect(health['storageAvailable'], isTrue);
    });

    testWidgets('AppLoading renders spinner and message cleanly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLoading(message: 'Initializing Cipher-X Security...'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Initializing Cipher-X Security...'), findsOneWidget);
    });

    testWidgets(
      'AppErrorView renders error title, description & handles retry action',
      (WidgetTester tester) async {
        bool retried = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppErrorView(
                title: 'Connection Lost',
                message: 'Failed to connect to security gateway.',
                onRetry: () {
                  retried = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('Connection Lost'), findsOneWidget);
        expect(
          find.text('Failed to connect to security gateway.'),
          findsOneWidget,
        );
        expect(find.text('Try Again'), findsOneWidget);

        await tester.tap(find.text('Try Again'));
        await tester.pumpAndSettle();
        expect(retried, isTrue);
      },
    );
  });
}

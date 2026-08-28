import 'package:cipher_x/features/location/domain/entities/location_data.dart';
import 'package:cipher_x/features/location/domain/entities/location_permission_state.dart';
import 'package:cipher_x/features/location/presentation/providers/location_providers.dart';
import 'package:cipher_x/features/location/presentation/widgets/location_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_location_service.dart';

void main() {
  group('LocationStatusCard Widget Tests', () {
    late FakeLocationService fakeService;

    setUp(() {
      fakeService = FakeLocationService();
    });

    Widget createWidgetUnderTest() {
      return ProviderScope(
        overrides: [
          locationServiceProvider.overrideWithValue(fakeService),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LocationStatusCard(),
            ),
          ),
        ),
      );
    }

    testWidgets('renders GPS Location Service card header & button',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('GPS Location Service'), findsOneWidget);
      expect(find.text('Acquire Current Location'), findsOneWidget);
      expect(find.text('Granted'), findsOneWidget);
    });

    testWidgets('displays coordinates after tapping Acquire Current Location',
        (tester) async {
      fakeService.currentLocationData = LocationData(
        latitude: 18.5204,
        longitude: 73.8567,
        accuracy: 10.0,
        timestamp: DateTime.utc(2026, 8, 28, 12, 0),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Acquire Current Location'));
      await tester.pump(); // Start loading
      await tester.pumpAndSettle(); // Finish fetch

      expect(find.text('18.520400'), findsOneWidget);
      expect(find.text('73.856700'), findsOneWidget);
      expect(find.text('±10.0 m'), findsOneWidget);
      expect(find.text('Refresh GPS Location'), findsOneWidget);
    });

    testWidgets('displays error banner when GPS is disabled', (tester) async {
      fakeService.isServiceEnabled = false;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(
        find.text('GPS location services are disabled on this device.'),
        findsOneWidget,
      );
    });

    testWidgets('displays permission badge as Denied when permission is denied',
        (tester) async {
      fakeService.permissionState = LocationPermissionState.denied;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Denied'), findsOneWidget);
    });
  });
}

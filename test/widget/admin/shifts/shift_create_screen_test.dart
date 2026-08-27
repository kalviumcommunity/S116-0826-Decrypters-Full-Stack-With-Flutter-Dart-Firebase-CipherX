import 'package:cipher_x/features/admin/presentation/screens/shifts/shift_create_screen.dart';
import 'package:cipher_x/features/guards/domain/entities/guard.dart';
import 'package:cipher_x/features/guards/presentation/providers/guard_providers.dart';
import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';
import 'package:cipher_x/features/identity/presentation/providers/identity_providers.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';
import 'package:cipher_x/features/sites/presentation/providers/site_providers.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift.dart';
import 'package:cipher_x/features/shifts/domain/failures/shift_failure.dart';
import 'package:cipher_x/features/shifts/domain/repositories/shift_repository.dart';
import 'package:cipher_x/features/shifts/presentation/providers/shift_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeShiftRepository implements ShiftRepository {
  final bool shouldFail;
  final ShiftFailure? failure;
  Shift? createdShift;

  FakeShiftRepository({this.shouldFail = false, this.failure});

  @override
  Future<Shift> createShift(Shift shift) async {
    if (shouldFail) {
      throw failure ?? const ShiftValidationFailure('Database error');
    }
    createdShift = shift;
    return shift;
  }

  @override
  Future<Shift?> getShift(
      {required String organizationId, required String shiftId}) async {
    return createdShift;
  }

  @override
  Future<List<Shift>> getShiftsByOrganization(String organizationId,
      {DateTime? date, ShiftStatus? status}) async {
    return createdShift != null ? [createdShift!] : [];
  }

  @override
  Future<List<Shift>> getShiftsByGuard(String organizationId, String guardId,
      {DateTime? date}) async {
    return createdShift != null ? [createdShift!] : [];
  }

  @override
  Future<List<Shift>> getShiftsBySite(String organizationId, String siteId,
      {DateTime? date}) async {
    return createdShift != null ? [createdShift!] : [];
  }

  @override
  Future<Shift> updateShift(Shift shift) async {
    createdShift = shift;
    return shift;
  }

  @override
  Future<Shift> updateShiftStatus({
    required String organizationId,
    required String shiftId,
    required ShiftStatus status,
  }) async {
    if (createdShift != null) {
      createdShift = createdShift!.copyWith(status: status);
      return createdShift!;
    }
    throw const ShiftNotFoundFailure();
  }

  @override
  Future<void> cancelShift({
    required String organizationId,
    required String shiftId,
  }) async {
    await updateShiftStatus(
      organizationId: organizationId,
      shiftId: shiftId,
      status: ShiftStatus.cancelled,
    );
  }
}

void main() {
  const testProfile = UserProfile(
    uid: 'admin-1',
    organizationId: 'org-test',
    role: UserRole.admin,
    displayName: 'Admin User',
    phone: '+1 555-0100',
    email: 'admin@cipherx.com',
  );

  const testGuard = Guard(
    guardId: 'g-101',
    organizationId: 'org-test',
    name: 'Rahul Sharma',
    employeeId: 'G-1024',
    phone: '+1 555-0199',
    status: GuardStatus.active,
  );

  const testSite = Site(
    siteId: 'site-202',
    organizationId: 'org-test',
    name: 'Cyber Gateway Tech Park',
    address: '123 Cyber Way',
    latitude: 17.44,
    longitude: 78.38,
    geofenceRadius: 50.0,
    status: SiteStatus.active,
  );

  group('ShiftCreateScreen Widget Tests', () {
    testWidgets('Renders all initial form fields and header', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider
                .overrideWith((ref) => const AsyncData(testProfile)),
            guardsStreamProvider
                .overrideWith((ref) => Stream.value([testGuard])),
            sitesStreamProvider.overrideWith((ref) => Stream.value([testSite])),
          ],
          child: const MaterialApp(home: ShiftCreateScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Create Shift'), findsNWidgets(2));
      expect(find.text('Guard'), findsOneWidget);
      expect(find.text('Site'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Start Time'), findsOneWidget);
      expect(find.text('End Time'), findsOneWidget);
      expect(find.byKey(const Key('create_shift_button')), findsOneWidget);
    });

    testWidgets('Shows validation errors when submitting unselected form',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider
                .overrideWith((ref) => const AsyncData(testProfile)),
            guardsStreamProvider
                .overrideWith((ref) => Stream.value([testGuard])),
            sitesStreamProvider.overrideWith((ref) => Stream.value([testSite])),
          ],
          child: const MaterialApp(home: ShiftCreateScreen()),
        ),
      );

      await tester.pumpAndSettle();

      final createBtn = find.byKey(const Key('create_shift_button'));
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please select a guard.'), findsOneWidget);
      expect(find.text('Please select a site.'), findsOneWidget);
      expect(find.text('Please select a shift date.'), findsOneWidget);
      expect(find.text('Please select a start time.'), findsOneWidget);
      expect(find.text('Please select an end time.'), findsOneWidget);
    });

    testWidgets('Displays empty state message when no active guards available',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider
                .overrideWith((ref) => const AsyncData(testProfile)),
            guardsStreamProvider.overrideWith((ref) => Stream.value(<Guard>[])),
            sitesStreamProvider.overrideWith((ref) => Stream.value([testSite])),
          ],
          child: const MaterialApp(home: ShiftCreateScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(
          find.textContaining('No active guards available.'), findsOneWidget);
    });

    testWidgets('Displays empty state message when no active sites available',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider
                .overrideWith((ref) => const AsyncData(testProfile)),
            guardsStreamProvider
                .overrideWith((ref) => Stream.value([testGuard])),
            sitesStreamProvider.overrideWith((ref) => Stream.value(<Site>[])),
          ],
          child: const MaterialApp(home: ShiftCreateScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('No active sites available.'), findsOneWidget);
    });

    testWidgets('Displays error UI and retry button when guards stream fails',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider
                .overrideWith((ref) => const AsyncData(testProfile)),
            guardsStreamProvider
                .overrideWith((ref) => Stream.error('Network Error')),
            sitesStreamProvider.overrideWith((ref) => Stream.value([testSite])),
          ],
          child: const MaterialApp(home: ShiftCreateScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to load guards.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Displays error UI and retry button when sites stream fails',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider
                .overrideWith((ref) => const AsyncData(testProfile)),
            guardsStreamProvider
                .overrideWith((ref) => Stream.value([testGuard])),
            sitesStreamProvider
                .overrideWith((ref) => Stream.error('Network Error')),
          ],
          child: const MaterialApp(home: ShiftCreateScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to load sites.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets(
        'Selecting guard and site updates form state and displays summary card',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider
                .overrideWith((ref) => const AsyncData(testProfile)),
            guardsStreamProvider
                .overrideWith((ref) => Stream.value([testGuard])),
            sitesStreamProvider.overrideWith((ref) => Stream.value([testSite])),
          ],
          child: const MaterialApp(home: ShiftCreateScreen()),
        ),
      );

      await tester.pumpAndSettle();

      final guardDropdown = find.byKey(const Key('guard_dropdown'));
      await tester.tap(guardDropdown);
      await tester.pumpAndSettle();

      final guardOption = find.text('Rahul Sharma (G-1024)').last;
      await tester.tap(guardOption);
      await tester.pumpAndSettle();

      final siteDropdown = find.byKey(const Key('site_dropdown'));
      await tester.tap(siteDropdown);
      await tester.pumpAndSettle();

      final siteOption =
          find.text('Cyber Gateway Tech Park — 123 Cyber Way').last;
      await tester.tap(siteOption);
      await tester.pumpAndSettle();

      expect(find.text('Shift Summary'), findsOneWidget);
      expect(find.text('Rahul Sharma'), findsOneWidget);
      expect(find.text('Cyber Gateway Tech Park'), findsOneWidget);
    });

    testWidgets(
        'Displays SnackBar on ShiftConflictFailure and retains form values',
        (tester) async {
      final fakeRepo = FakeShiftRepository(
        shouldFail: true,
        failure: const ShiftConflictFailure(
            'This guard already has another shift during the selected time.'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider
                .overrideWith((ref) => const AsyncData(testProfile)),
            guardsStreamProvider
                .overrideWith((ref) => Stream.value([testGuard])),
            sitesStreamProvider.overrideWith((ref) => Stream.value([testSite])),
            shiftRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(home: ShiftCreateScreen()),
        ),
      );

      await tester.pumpAndSettle();

      final guardDropdown = find.byKey(const Key('guard_dropdown'));
      await tester.tap(guardDropdown);
      await tester.pumpAndSettle();

      final guardOption = find.text('Rahul Sharma (G-1024)').last;
      await tester.tap(guardOption);
      await tester.pumpAndSettle();

      final siteDropdown = find.byKey(const Key('site_dropdown'));
      await tester.tap(siteDropdown);
      await tester.pumpAndSettle();

      final siteOption =
          find.text('Cyber Gateway Tech Park — 123 Cyber Way').last;
      await tester.tap(siteOption);
      await tester.pumpAndSettle();

      final dateTile = find.byKey(const Key('date_picker_button'));
      await tester.ensureVisible(dateTile);
      await tester.tap(dateTile);
      await tester.pumpAndSettle();
      final okBtn = find.text('OK');
      if (okBtn.evaluate().isNotEmpty) {
        await tester.tap(okBtn.last);
        await tester.pumpAndSettle();
      }

      final startTimeTile = find.byKey(const Key('start_time_picker_button'));
      await tester.ensureVisible(startTimeTile);
      await tester.tap(startTimeTile);
      await tester.pumpAndSettle();
      if (okBtn.evaluate().isNotEmpty) {
        await tester.tap(okBtn.last);
        await tester.pumpAndSettle();
      }

      final endTimeTile = find.byKey(const Key('end_time_picker_button'));
      await tester.ensureVisible(endTimeTile);
      await tester.tap(endTimeTile);
      await tester.pumpAndSettle();
      if (okBtn.evaluate().isNotEmpty) {
        await tester.tap(okBtn.last);
        await tester.pumpAndSettle();
      }

      final createBtn = find.byKey(const Key('create_shift_button'));
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(
        find.text(
            'This guard already has another shift during the selected time.'),
        findsOneWidget,
      );
      // Form values are preserved
      expect(find.text('Shift Summary'), findsOneWidget);
      expect(find.text('Rahul Sharma'), findsOneWidget);
    });
  });
}

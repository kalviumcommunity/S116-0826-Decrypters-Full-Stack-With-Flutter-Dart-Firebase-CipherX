import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cipher_x/features/guards/data/datasources/firebase_guard_data_source.dart';
import 'package:cipher_x/features/guards/data/repositories/guard_repository_impl.dart';
import 'package:cipher_x/features/guards/domain/entities/guard.dart';
import 'package:cipher_x/features/guards/domain/failures/guard_failure.dart';

class MockFirebaseGuardDataSource extends Mock
    implements FirebaseGuardDataSource {}

void main() {
  late MockFirebaseGuardDataSource mockDataSource;
  late GuardRepositoryImpl repository;

  const tGuard = Guard(
    guardId: 'test-guard-001',
    organizationId: 'test-org-001',
    name: 'Officer Alex',
    employeeId: 'EMP-1001',
    phone: '+1 555-0199',
    email: 'alex@cipherx.com',
    status: GuardStatus.active,
  );

  setUpAll(() {
    registerFallbackValue(
      const Guard(
        guardId: 'fallback',
        organizationId: 'fallback',
        name: 'Fallback',
        employeeId: 'EMP-00',
        phone: '+1 555-0000',
      ),
    );
  });

  setUp(() {
    mockDataSource = MockFirebaseGuardDataSource();
    repository = GuardRepositoryImpl(dataSource: mockDataSource);
  });

  group('GuardRepositoryImpl Unit Tests', () {
    test('createGuard validates and delegates to data source', () async {
      when(() => mockDataSource.createGuard(any()))
          .thenAnswer((_) async => tGuard);

      final result = await repository.createGuard(tGuard);

      expect(result, equals(tGuard));
      verify(() => mockDataSource.createGuard(any())).called(1);
    });

    test('getGuard returns guard when found in organization scope', () async {
      when(
        () => mockDataSource.getGuard(
          organizationId: 'test-org-001',
          guardId: 'test-guard-001',
        ),
      ).thenAnswer((_) async => tGuard);

      final result = await repository.getGuard(
        organizationId: 'test-org-001',
        guardId: 'test-guard-001',
      );

      expect(result, equals(tGuard));
      verify(
        () => mockDataSource.getGuard(
          organizationId: 'test-org-001',
          guardId: 'test-guard-001',
        ),
      ).called(1);
    });

    test('getGuard returns null when document does not exist', () async {
      when(
        () => mockDataSource.getGuard(
          organizationId: 'test-org-001',
          guardId: 'missing-guard',
        ),
      ).thenAnswer((_) async => null);

      final result = await repository.getGuard(
        organizationId: 'test-org-001',
        guardId: 'missing-guard',
      );

      expect(result, isNull);
    });

    test(
      'getGuards returns list of guards for specified organization',
      () async {
        when(() => mockDataSource.getGuards('test-org-001'))
            .thenAnswer((_) async => [tGuard]);

        final result = await repository.getGuards('test-org-001');

        expect(result, hasLength(1));
        expect(result.first, equals(tGuard));
        verify(() => mockDataSource.getGuards('test-org-001')).called(1);
      },
    );

    test(
      'updateGuardStatus delegates to data source with correct parameters',
      () async {
        final updatedGuard = tGuard.copyWith(status: GuardStatus.inactive);
        when(
          () => mockDataSource.updateGuardStatus(
            organizationId: 'test-org-001',
            guardId: 'test-guard-001',
            status: GuardStatus.inactive,
          ),
        ).thenAnswer((_) async => updatedGuard);

        final result = await repository.updateGuardStatus(
          organizationId: 'test-org-001',
          guardId: 'test-guard-001',
          status: GuardStatus.inactive,
        );

        expect(result.status, GuardStatus.inactive);
        verify(
          () => mockDataSource.updateGuardStatus(
            organizationId: 'test-org-001',
            guardId: 'test-guard-001',
            status: GuardStatus.inactive,
          ),
        ).called(1);
      },
    );

    test(
      'deleteGuard performs soft deletion via status deactivation',
      () async {
        when(
          () => mockDataSource.deleteGuard(
            organizationId: 'test-org-001',
            guardId: 'test-guard-001',
          ),
        ).thenAnswer((_) async {});

        await repository.deleteGuard(
          organizationId: 'test-org-001',
          guardId: 'test-guard-001',
        );

        verify(
          () => mockDataSource.deleteGuard(
            organizationId: 'test-org-001',
            guardId: 'test-guard-001',
          ),
        ).called(1);
      },
    );

    test(
      'maps permission-denied FirebaseException to PermissionDeniedFailure',
      () async {
        when(
          () => mockDataSource.getGuard(
            organizationId: 'test-org-001',
            guardId: 'test-guard-001',
          ),
        ).thenThrow(
          FirebaseException(plugin: 'firestore', code: 'permission-denied'),
        );

        expect(
          () => repository.getGuard(
            organizationId: 'test-org-001',
            guardId: 'test-guard-001',
          ),
          throwsA(isA<PermissionDeniedFailure>()),
        );
      },
    );

    test(
      'throws GuardValidationFailure when organizationId is empty on query',
      () async {
        expect(
          () => repository.getGuards(''),
          throwsA(isA<GuardValidationFailure>()),
        );
      },
    );
  });
}

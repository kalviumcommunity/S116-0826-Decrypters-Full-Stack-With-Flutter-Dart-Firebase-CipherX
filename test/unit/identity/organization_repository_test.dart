import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cipher_x/features/identity/data/datasources/firebase_organization_data_source.dart';
import 'package:cipher_x/features/identity/data/repositories/organization_repository_impl.dart';
import 'package:cipher_x/features/identity/domain/entities/organization.dart';
import 'package:cipher_x/features/identity/domain/failures/identity_failure.dart';

class MockFirebaseOrganizationDataSource extends Mock
    implements FirebaseOrganizationDataSource {}

void main() {
  late MockFirebaseOrganizationDataSource mockDataSource;
  late OrganizationRepositoryImpl repository;

  const tOrg = Organization(
    id: 'org_001',
    name: 'Apex Security Services',
    code: 'ORG001',
  );

  setUp(() {
    mockDataSource = MockFirebaseOrganizationDataSource();
    repository = OrganizationRepositoryImpl(dataSource: mockDataSource);
  });

  group('OrganizationRepositoryImpl Unit Tests', () {
    test('getOrganizationById returns organization when found', () async {
      when(() => mockDataSource.getOrganizationById('org_001'))
          .thenAnswer((_) async => tOrg);

      final result = await repository.getOrganizationById('org_001');

      expect(result, equals(tOrg));
      verify(() => mockDataSource.getOrganizationById('org_001')).called(1);
    });

    test('getOrganizationByCode returns organization when found', () async {
      when(() => mockDataSource.getOrganizationByCode('ORG001'))
          .thenAnswer((_) async => tOrg);

      final result = await repository.getOrganizationByCode('ORG001');

      expect(result, equals(tOrg));
      verify(() => mockDataSource.getOrganizationByCode('ORG001')).called(1);
    });

    test(
      'maps permission-denied FirebaseException to PermissionDeniedFailure',
      () async {
        when(() => mockDataSource.getOrganizationById('org_001')).thenThrow(
          FirebaseException(plugin: 'firestore', code: 'permission-denied'),
        );

        expect(
          () => repository.getOrganizationById('org_001'),
          throwsA(isA<PermissionDeniedFailure>()),
        );
      },
    );
  });
}

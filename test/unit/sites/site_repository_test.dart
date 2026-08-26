import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cipher_x/features/sites/data/datasources/firebase_site_data_source.dart';
import 'package:cipher_x/features/sites/data/repositories/site_repository_impl.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';
import 'package:cipher_x/features/sites/domain/failures/site_failure.dart';

class MockFirebaseSiteDataSource extends Mock
    implements FirebaseSiteDataSource {}

void main() {
  late MockFirebaseSiteDataSource mockDataSource;
  late SiteRepositoryImpl repository;

  const tSite = Site(
    siteId: 'test-site-001',
    organizationId: 'test-org-001',
    name: 'Security HQ',
    address: '456 Guard Ave',
    latitude: 19.0760,
    longitude: 72.8777,
    geofenceRadius: 100.0,
    status: SiteStatus.active,
  );

  setUpAll(() {
    registerFallbackValue(const Site(
      siteId: 'fallback',
      organizationId: 'fallback',
      name: 'Fallback',
      address: 'Fallback Address',
      latitude: 0.0,
      longitude: 0.0,
      geofenceRadius: 10.0,
    ));
  });

  setUp(() {
    mockDataSource = MockFirebaseSiteDataSource();
    repository = SiteRepositoryImpl(dataSource: mockDataSource);
  });

  group('SiteRepositoryImpl Unit Tests', () {
    test(
      'createSite validates and delegates to data source',
      () async {
        when(() => mockDataSource.createSite(any()))
            .thenAnswer((_) async => tSite);

        final result = await repository.createSite(tSite);

        expect(result, equals(tSite));
        verify(() => mockDataSource.createSite(any())).called(1);
      },
    );

    test(
      'getSite returns site when found in organization scope',
      () async {
        when(() => mockDataSource.getSite(
              organizationId: 'test-org-001',
              siteId: 'test-site-001',
            )).thenAnswer((_) async => tSite);

        final result = await repository.getSite(
          organizationId: 'test-org-001',
          siteId: 'test-site-001',
        );

        expect(result, equals(tSite));
        verify(() => mockDataSource.getSite(
              organizationId: 'test-org-001',
              siteId: 'test-site-001',
            )).called(1);
      },
    );

    test(
      'getSite returns null when document does not exist',
      () async {
        when(() => mockDataSource.getSite(
              organizationId: 'test-org-001',
              siteId: 'missing-site',
            )).thenAnswer((_) async => null);

        final result = await repository.getSite(
          organizationId: 'test-org-001',
          siteId: 'missing-site',
        );

        expect(result, isNull);
      },
    );

    test(
      'getSites returns list of sites for specified organization',
      () async {
        when(() => mockDataSource.getSites(
              'test-org-001',
              includeInactive: false,
            )).thenAnswer((_) async => [tSite]);

        final result = await repository.getSites('test-org-001');

        expect(result, hasLength(1));
        expect(result.first, equals(tSite));
        verify(() => mockDataSource.getSites(
              'test-org-001',
              includeInactive: false,
            )).called(1);
      },
    );

    test(
      'getSites with includeInactive: true delegates parameter',
      () async {
        when(() => mockDataSource.getSites(
              'test-org-001',
              includeInactive: true,
            )).thenAnswer((_) async => [tSite]);

        final result = await repository.getSites(
          'test-org-001',
          includeInactive: true,
        );

        expect(result, hasLength(1));
        verify(() => mockDataSource.getSites(
              'test-org-001',
              includeInactive: true,
            )).called(1);
      },
    );

    test(
      'updateSite validates and delegates to data source',
      () async {
        final updatedSite = tSite.copyWith(name: 'Updated Name');
        when(() => mockDataSource.updateSite(any()))
            .thenAnswer((_) async => updatedSite);

        final result = await repository.updateSite(tSite);

        expect(result, equals(updatedSite));
        verify(() => mockDataSource.updateSite(any())).called(1);
      },
    );

    test(
      'updateSiteStatus delegates to data source with correct parameters',
      () async {
        final updatedSite = tSite.copyWith(status: SiteStatus.inactive);
        when(() => mockDataSource.updateSiteStatus(
              organizationId: 'test-org-001',
              siteId: 'test-site-001',
              status: SiteStatus.inactive,
            )).thenAnswer((_) async => updatedSite);

        final result = await repository.updateSiteStatus(
          organizationId: 'test-org-001',
          siteId: 'test-site-001',
          status: SiteStatus.inactive,
        );

        expect(result.status, SiteStatus.inactive);
        verify(() => mockDataSource.updateSiteStatus(
              organizationId: 'test-org-001',
              siteId: 'test-site-001',
              status: SiteStatus.inactive,
            )).called(1);
      },
    );

    test(
      'updateSiteStatus maps not-found FirebaseException to SiteNotFoundFailure',
      () async {
        when(() => mockDataSource.updateSiteStatus(
              organizationId: 'test-org-001',
              siteId: 'missing-site',
              status: SiteStatus.inactive,
            )).thenThrow(
          FirebaseException(plugin: 'firestore', code: 'not-found'),
        );

        expect(
          () => repository.updateSiteStatus(
            organizationId: 'test-org-001',
            siteId: 'missing-site',
            status: SiteStatus.inactive,
          ),
          throwsA(isA<SiteNotFoundFailure>()),
        );
      },
    );

    test(
      'deleteSite performs soft deletion via status deactivation',
      () async {
        when(() => mockDataSource.deleteSite(
              organizationId: 'test-org-001',
              siteId: 'test-site-001',
            )).thenAnswer((_) async {});

        await repository.deleteSite(
          organizationId: 'test-org-001',
          siteId: 'test-site-001',
        );

        verify(() => mockDataSource.deleteSite(
              organizationId: 'test-org-001',
              siteId: 'test-site-001',
            )).called(1);
      },
    );

    test(
      'maps permission-denied FirebaseException to PermissionDeniedFailure',
      () async {
        when(() => mockDataSource.getSite(
              organizationId: 'test-org-001',
              siteId: 'test-site-001',
            )).thenThrow(
          FirebaseException(plugin: 'firestore', code: 'permission-denied'),
        );

        expect(
          () => repository.getSite(
            organizationId: 'test-org-001',
            siteId: 'test-site-001',
          ),
          throwsA(isA<PermissionDeniedFailure>()),
        );
      },
    );

    test(
      'throws SiteValidationFailure when organizationId is empty on query',
      () async {
        expect(
          () => repository.getSites(''),
          throwsA(isA<SiteValidationFailure>()),
        );
      },
    );
  });
}

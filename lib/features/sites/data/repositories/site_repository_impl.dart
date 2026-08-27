import '../../domain/entities/site.dart';
import '../../domain/repositories/site_repository.dart';
import '../datasources/firebase_site_data_source.dart';

class SiteRepositoryImpl implements SiteRepository {
  final FirebaseSiteDataSource _dataSource;

  SiteRepositoryImpl({required FirebaseSiteDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<Site> createSite(Site site) {
    return _dataSource.createSite(site);
  }

  @override
  Future<Site?> getSite({
    required String organizationId,
    required String siteId,
  }) {
    return _dataSource.getSite(
      organizationId: organizationId,
      siteId: siteId,
    );
  }

  @override
  Future<List<Site>> getSites(
    String organizationId, {
    bool includeInactive = false,
  }) {
    return _dataSource.getSites(
      organizationId,
      includeInactive: includeInactive,
    );
  }

  @override
  Stream<List<Site>> watchSites(
    String organizationId, {
    bool includeInactive = false,
  }) {
    return _dataSource.watchSites(
      organizationId,
      includeInactive: includeInactive,
    );
  }
}

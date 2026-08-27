import '../entities/site.dart';

abstract class SiteRepository {
  Future<Site> createSite(Site site);

  Future<Site?> getSite({
    required String organizationId,
    required String siteId,
  });

  Future<List<Site>> getSites(
    String organizationId, {
    bool includeInactive = false,
  });

  Stream<List<Site>> watchSites(
    String organizationId, {
    bool includeInactive = false,
  });
}

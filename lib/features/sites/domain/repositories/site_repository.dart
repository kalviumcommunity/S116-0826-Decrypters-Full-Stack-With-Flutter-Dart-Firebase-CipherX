import '../entities/site.dart';

/// Repository abstraction for managing security sites within an organization context.
///
/// All operations are organization-scoped to enforce multi-tenant security boundaries.
abstract class SiteRepository {
  /// Validates and persists a new [site] document in Firestore.
  ///
  /// Throws [SiteValidationFailure] if site fields fail domain validation rules.
  Future<Site> createSite(Site site);

  /// Retrieves a specific site by [organizationId] and [siteId].
  ///
  /// Returns `null` if the site document does not exist.
  Future<Site?> getSite({
    required String organizationId,
    required String siteId,
  });

  /// Retrieves all sites belonging to the specified [organizationId].
  Future<List<Site>> getSites(String organizationId);

  /// Validates and updates mutable fields of an existing [site].
  ///
  /// Immutable fields (`siteId`, `organizationId`, `createdAt`) are preserved.
  Future<Site> updateSite(Site site);

  /// Updates the status of a site.
  Future<Site> updateSiteStatus({
    required String organizationId,
    required String siteId,
    required SiteStatus status,
  });

  /// Deactivates a site by setting its status to [SiteStatus.inactive].
  ///
  /// Operational history (shifts, attendance, incidents) is preserved.
  Future<void> deleteSite({
    required String organizationId,
    required String siteId,
  });
}

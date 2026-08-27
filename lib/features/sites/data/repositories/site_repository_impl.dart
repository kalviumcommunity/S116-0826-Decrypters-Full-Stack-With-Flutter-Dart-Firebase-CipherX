import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/site.dart';
import '../../domain/failures/site_failure.dart';
import '../../domain/repositories/site_repository.dart';
import '../../domain/validators/site_validator.dart';
import '../datasources/firebase_site_data_source.dart';

class SiteRepositoryImpl implements SiteRepository {
  final FirebaseSiteDataSource _dataSource;

  SiteRepositoryImpl({
    required FirebaseSiteDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<Site> createSite(Site site) async {
    try {
      final normalized = SiteValidator.validate(site);
      return await _dataSource.createSite(normalized);
    } on SiteFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownSiteFailure(e.toString());
    }
  }

  @override
  Future<Site?> getSite({
    required String organizationId,
    required String siteId,
  }) async {
    try {
      if (organizationId.trim().isEmpty) {
        throw const SiteValidationFailure('Organization ID cannot be empty.');
      }
      if (siteId.trim().isEmpty) {
        throw const SiteValidationFailure('Site ID cannot be empty.');
      }
      return await _dataSource.getSite(
        organizationId: organizationId.trim(),
        siteId: siteId.trim(),
      );
    } on SiteFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownSiteFailure(e.toString());
    }
  }

  @override
  Future<List<Site>> getSites(
    String organizationId, {
    bool includeInactive = false,
  }) async {
    try {
      if (organizationId.trim().isEmpty) {
        throw const SiteValidationFailure('Organization ID cannot be empty.');
      }
      return await _dataSource.getSites(
        organizationId.trim(),
        includeInactive: includeInactive,
      );
    } on SiteFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownSiteFailure(e.toString());
    }
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

  @override
  Future<Site> updateSite(Site site) async {
    try {
      if (site.siteId.trim().isEmpty) {
        throw const SiteValidationFailure('Site ID cannot be empty.');
      }
      final normalized = SiteValidator.validate(site);
      return await _dataSource.updateSite(normalized);
    } on SiteFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownSiteFailure(e.toString());
    }
  }

  @override
  Future<Site> updateSiteStatus({
    required String organizationId,
    required String siteId,
    required SiteStatus status,
  }) async {
    try {
      if (organizationId.trim().isEmpty) {
        throw const SiteValidationFailure('Organization ID cannot be empty.');
      }
      if (siteId.trim().isEmpty) {
        throw const SiteValidationFailure('Site ID cannot be empty.');
      }
      return await _dataSource.updateSiteStatus(
        organizationId: organizationId.trim(),
        siteId: siteId.trim(),
        status: status,
      );
    } on SiteFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownSiteFailure(e.toString());
    }
  }

  @override
  Future<void> deleteSite({
    required String organizationId,
    required String siteId,
  }) async {
    try {
      if (organizationId.trim().isEmpty) {
        throw const SiteValidationFailure('Organization ID cannot be empty.');
      }
      if (siteId.trim().isEmpty) {
        throw const SiteValidationFailure('Site ID cannot be empty.');
      }
      await _dataSource.deleteSite(
        organizationId: organizationId.trim(),
        siteId: siteId.trim(),
      );
    } on SiteFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownSiteFailure(e.toString());
    }
  }

  SiteFailure _mapFirebaseException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const PermissionDeniedFailure();
      case 'not-found':
        return const SiteNotFoundFailure();
      case 'unavailable':
        return const FirestoreFailure(
          'Database is temporarily unavailable. Check network connectivity.',
        );
      default:
        return FirestoreFailure(e.message ?? 'Firestore error occurred.');
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';
import 'package:cipher_x/features/sites/domain/repositories/site_repository.dart';
import 'package:cipher_x/features/sites/presentation/providers/site_providers.dart';
import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';
import 'package:cipher_x/features/identity/presentation/providers/identity_providers.dart';

class FakeSiteRepository implements SiteRepository {
  final List<Site> sites = [];
  bool shouldThrow = false;

  @override
  Future<Site> createSite(Site site) async {
    if (shouldThrow) throw Exception('Failed to create site');
    final created =
        site.copyWith(siteId: site.siteId.isEmpty ? 'site-123' : site.siteId);
    sites.add(created);
    return created;
  }

  @override
  Future<Site?> getSite(
      {required String organizationId, required String siteId}) async {
    if (shouldThrow) throw Exception('Failed to get site');
    try {
      return sites.firstWhere(
          (s) => s.siteId == siteId && s.organizationId == organizationId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Site>> getSites(
    String organizationId, {
    bool includeInactive = false,
  }) async {
    if (shouldThrow) throw Exception('Failed to get sites');
    return sites.where((s) {
      if (s.organizationId != organizationId) return false;
      if (!includeInactive && s.status != SiteStatus.active) return false;
      return true;
    }).toList();
  }

  @override
  Stream<List<Site>> watchSites(
    String organizationId, {
    bool includeInactive = false,
  }) async* {
    if (shouldThrow) throw Exception('Failed to watch sites');
    yield await getSites(organizationId, includeInactive: includeInactive);
  }

  @override
  Future<Site> updateSite(Site site) async {
    if (shouldThrow) throw Exception('Failed to update site');
    final index = sites.indexWhere((s) => s.siteId == site.siteId);
    if (index != -1) {
      sites[index] = site;
    } else {
      sites.add(site);
    }
    return site;
  }

  @override
  Future<Site> updateSiteStatus({
    required String organizationId,
    required String siteId,
    required SiteStatus status,
  }) async {
    if (shouldThrow) throw Exception('Failed to update status');
    final index = sites.indexWhere((s) => s.siteId == siteId);
    if (index != -1) {
      final updated = sites[index].copyWith(status: status);
      sites[index] = updated;
      return updated;
    }
    throw Exception('Site not found');
  }

  @override
  Future<void> deleteSite({
    required String organizationId,
    required String siteId,
  }) async {
    if (shouldThrow) throw Exception('Failed to delete site');
    await updateSiteStatus(
      organizationId: organizationId,
      siteId: siteId,
      status: SiteStatus.inactive,
    );
  }
}

void main() {
  const tSite = Site(
    siteId: 'site-001',
    organizationId: 'org-001',
    name: 'HQ Campus',
    address: '123 Tech Way',
    latitude: 18.5204,
    longitude: 73.8567,
    geofenceRadius: 500.0,
    status: SiteStatus.active,
  );

  group('SiteController Unit Tests', () {
    late FakeSiteRepository fakeRepo;
    late ProviderContainer container;

    const tProfile = UserProfile(
      uid: 'user-100',
      email: 'admin@cipherx.com',
      displayName: 'Admin',
      phone: '+1 555-0100',
      role: UserRole.admin,
      organizationId: 'org-001',
    );

    setUp(() {
      fakeRepo = FakeSiteRepository();
      container = ProviderContainer(
        overrides: [
          siteRepositoryProvider.overrideWithValue(fakeRepo),
          currentUserProfileProvider
              .overrideWith((ref) => const AsyncData(tProfile)),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('createSite returns true and adds site on success', () async {
      final controller = container.read(siteControllerProvider.notifier);
      final success = await controller.createSite(tSite);

      expect(success, isTrue);
      expect(fakeRepo.sites.length, equals(1));
      expect(fakeRepo.sites.first.name, equals('HQ Campus'));
    });

    test('createSite returns false and sets AsyncError on failure', () async {
      fakeRepo.shouldThrow = true;
      final controller = container.read(siteControllerProvider.notifier);
      final success = await controller.createSite(tSite);

      expect(success, isFalse);
      final state = container.read(siteControllerProvider);
      expect(state.hasError, isTrue);
    });

    test('updateSite returns true on success', () async {
      fakeRepo.sites.add(tSite);
      final updated = tSite.copyWith(name: 'Updated HQ Campus');

      final controller = container.read(siteControllerProvider.notifier);
      final success = await controller.updateSite(updated);

      expect(success, isTrue);
      expect(fakeRepo.sites.first.name, equals('Updated HQ Campus'));
    });

    test('updateSiteStatus returns true and updates status', () async {
      fakeRepo.sites.add(tSite);

      final controller = container.read(siteControllerProvider.notifier);
      final success = await controller.updateSiteStatus(
        organizationId: 'org-001',
        siteId: 'site-001',
        status: SiteStatus.inactive,
      );

      expect(success, isTrue);
      expect(fakeRepo.sites.first.status, equals(SiteStatus.inactive));
    });

    test('deleteSite deactivates site', () async {
      fakeRepo.sites.add(tSite);

      final controller = container.read(siteControllerProvider.notifier);
      final success = await controller.deleteSite(
        organizationId: 'org-001',
        siteId: 'site-001',
      );

      expect(success, isTrue);
      expect(fakeRepo.sites.first.status, equals(SiteStatus.inactive));
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../identity/presentation/providers/identity_providers.dart';
import '../../data/datasources/firebase_site_data_source.dart';
import '../../data/repositories/site_repository_impl.dart';
import '../../domain/entities/site.dart';
import '../../domain/repositories/site_repository.dart';

final firebaseSiteDataSourceProvider = Provider<FirebaseSiteDataSource>((ref) {
  final firestore = ref.watch(cloudFirestoreProvider);
  return FirebaseSiteDataSource(firestore: firestore);
});

final siteRepositoryProvider = Provider<SiteRepository>((ref) {
  final dataSource = ref.watch(firebaseSiteDataSourceProvider);
  return SiteRepositoryImpl(dataSource: dataSource);
});

final sitesListProvider = FutureProvider.family
    .autoDispose<List<Site>, bool>((ref, includeInactive) async {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null || profile.organizationId.trim().isEmpty) {
    return const [];
  }

  final repository = ref.watch(siteRepositoryProvider);
  return await repository.getSites(
    profile.organizationId,
    includeInactive: includeInactive,
  );
});

final sitesStreamProvider = StreamProvider.autoDispose<List<Site>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null || profile.organizationId.trim().isEmpty) {
    return const Stream.empty();
  }

  final repository = ref.watch(siteRepositoryProvider);
  return repository.watchSites(
    profile.organizationId,
    includeInactive: false,
  );
});

class SiteController extends AutoDisposeAsyncNotifier<void> {
  @override
  void build() {}

  void _invalidateSites() {
    ref.invalidate(sitesListProvider(true));
    ref.invalidate(sitesListProvider(false));
    ref.invalidate(sitesStreamProvider);
  }

  Future<bool> createSite(Site site) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      final repository = ref.read(siteRepositoryProvider);
      await repository.createSite(site);
      state = const AsyncData(null);
      _invalidateSites();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updateSite(Site site) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      final repository = ref.read(siteRepositoryProvider);
      await repository.updateSite(site);
      state = const AsyncData(null);
      _invalidateSites();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updateSiteStatus({
    required String organizationId,
    required String siteId,
    required SiteStatus status,
  }) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      final repository = ref.read(siteRepositoryProvider);
      await repository.updateSiteStatus(
        organizationId: organizationId,
        siteId: siteId,
        status: status,
      );
      state = const AsyncData(null);
      _invalidateSites();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> deleteSite({
    required String organizationId,
    required String siteId,
  }) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      final repository = ref.read(siteRepositoryProvider);
      await repository.deleteSite(
        organizationId: organizationId,
        siteId: siteId,
      );
      state = const AsyncData(null);
      _invalidateSites();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final siteControllerProvider =
    AutoDisposeAsyncNotifierProvider<SiteController, void>(() {
  return SiteController();
});

final siteProvider = FutureProvider.family<Site?, String>((ref, siteId) async {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;
  if (profile == null) return null;

  final repository = ref.watch(siteRepositoryProvider);
  return await repository.getSite(
    organizationId: profile.organizationId,
    siteId: siteId,
  );
});

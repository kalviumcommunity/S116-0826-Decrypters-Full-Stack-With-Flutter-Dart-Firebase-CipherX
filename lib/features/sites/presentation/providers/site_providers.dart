import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../identity/presentation/providers/identity_providers.dart';
import '../../data/datasources/firebase_site_data_source.dart';
import '../../data/repositories/site_repository_impl.dart';
import '../../domain/entities/site.dart';
import '../../domain/repositories/site_repository.dart';

final firebaseSiteDataSourceProvider = Provider<FirebaseSiteDataSource>((
  ref,
) {
  final firestore = ref.watch(cloudFirestoreProvider);
  return FirebaseSiteDataSource(firestore: firestore);
});

final siteRepositoryProvider = Provider<SiteRepository>((ref) {
  final dataSource = ref.watch(firebaseSiteDataSourceProvider);
  return SiteRepositoryImpl(dataSource: dataSource);
});

final sitesStreamProvider = StreamProvider.autoDispose<List<Site>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null) {
    return const Stream.empty();
  }

  final repository = ref.watch(siteRepositoryProvider);
  return repository.watchSites(profile.organizationId);
});

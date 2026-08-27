import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/site.dart';

class FirebaseSiteDataSource {
  final FirebaseFirestore _firestore;

  FirebaseSiteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _sitesCollection =>
      _firestore.collection('sites');

  Future<Site> createSite(Site site) async {
    final docRef = site.id.trim().isNotEmpty
        ? _sitesCollection.doc(site.id.trim())
        : _sitesCollection.doc();

    final assignedId = docRef.id;
    final now = DateTime.now();
    final preparedSite = site.copyWith(
      id: assignedId,
      createdAt: site.createdAt ?? now,
      updatedAt: site.updatedAt ?? now,
    );

    final data = preparedSite.toMap();
    await docRef.set(data);
    final snapshot = await docRef.get();
    if (!snapshot.exists || snapshot.data() == null) {
      return preparedSite;
    }
    return Site.fromMap(snapshot.data()!);
  }

  Future<Site?> getSite({
    required String organizationId,
    required String siteId,
  }) async {
    final doc = await _sitesCollection.doc(siteId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    final site = Site.fromMap(doc.data()!);
    if (site.organizationId != organizationId) {
      return null;
    }
    return site;
  }

  Future<List<Site>> getSites(
    String organizationId, {
    bool includeInactive = false,
  }) async {
    Query<Map<String, dynamic>> query =
        _sitesCollection.where('organizationId', isEqualTo: organizationId);

    if (!includeInactive) {
      query = query.where('isActive', isEqualTo: true);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Site.fromMap(doc.data())).toList();
  }

  Stream<List<Site>> watchSites(
    String organizationId, {
    bool includeInactive = false,
  }) {
    Query<Map<String, dynamic>> query =
        _sitesCollection.where('organizationId', isEqualTo: organizationId);

    if (!includeInactive) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Site.fromMap(doc.data())).toList();
    });
  }
}

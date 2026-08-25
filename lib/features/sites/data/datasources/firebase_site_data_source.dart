import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/site.dart';

class FirebaseSiteDataSource {
  final FirebaseFirestore _firestore;

  FirebaseSiteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _sitesCollection(
          String organizationId) =>
      _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('sites');

  Future<Site> createSite(Site site) async {
    final collection = _sitesCollection(site.organizationId);
    final docRef = site.siteId.trim().isNotEmpty
        ? collection.doc(site.siteId.trim())
        : collection.doc();

    final assignedId = docRef.id;
    final data = site.copyWith(siteId: assignedId).toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.set(data);
    final snapshot = await docRef.get();
    if (!snapshot.exists || snapshot.data() == null) {
      return site.copyWith(siteId: assignedId);
    }
    return Site.fromMap(snapshot.data()!);
  }

  Future<Site?> getSite({
    required String organizationId,
    required String siteId,
  }) async {
    final doc = await _sitesCollection(organizationId).doc(siteId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return Site.fromMap(doc.data()!);
  }

  Future<List<Site>> getSites(String organizationId) async {
    final snapshot = await _sitesCollection(organizationId).get();
    return snapshot.docs.map((doc) => Site.fromMap(doc.data())).toList();
  }

  Future<Site> updateSite(Site site) async {
    final docRef =
        _sitesCollection(site.organizationId).doc(site.siteId);
    final updates = <String, dynamic>{
      'name': site.name,
      'address': site.address,
      'latitude': site.latitude,
      'longitude': site.longitude,
      'geofenceRadius': site.geofenceRadius,
      'status': site.status.toMapString(),
      'isActive': site.status == SiteStatus.active,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.update(updates);
    final snapshot = await docRef.get();
    if (!snapshot.exists || snapshot.data() == null) {
      return site;
    }
    return Site.fromMap(snapshot.data()!);
  }

  Future<Site> updateSiteStatus({
    required String organizationId,
    required String siteId,
    required SiteStatus status,
  }) async {
    final docRef = _sitesCollection(organizationId).doc(siteId);
    await docRef.update({
      'status': status.toMapString(),
      'isActive': status == SiteStatus.active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final snapshot = await docRef.get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('Site document does not exist after status update.');
    }
    return Site.fromMap(snapshot.data()!);
  }

  Future<void> deleteSite({
    required String organizationId,
    required String siteId,
  }) async {
    await updateSiteStatus(
      organizationId: organizationId,
      siteId: siteId,
      status: SiteStatus.inactive,
    );
  }
}

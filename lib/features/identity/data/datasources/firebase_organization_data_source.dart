import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/demo/demo_data.dart';
import '../../domain/entities/organization.dart';

class FirebaseOrganizationDataSource {
  final FirebaseFirestore _firestore;

  FirebaseOrganizationDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orgsCollection =>
      _firestore.collection('organizations');

  Future<Organization?> getOrganizationById(String id) async {
    if (id == DemoData.demoOrgId || id.trim().isEmpty) {
      return DemoData.demoOrganization;
    }
    try {
      final doc = await _orgsCollection.doc(id).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return Organization.fromMap(doc.data()!);
    } catch (_) {
      return DemoData.demoOrganization;
    }
  }

  Future<Organization?> getOrganizationByCode(String code) async {
    if (code.trim().toUpperCase() ==
        DemoData.demoOrganization.code.toUpperCase()) {
      return DemoData.demoOrganization;
    }
    try {
      final query = await _orgsCollection
          .where('code', isEqualTo: code.trim().toUpperCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        final queryExact = await _orgsCollection
            .where('code', isEqualTo: code.trim())
            .limit(1)
            .get();
        if (queryExact.docs.isEmpty) return null;
        return Organization.fromMap(queryExact.docs.first.data());
      }

      return Organization.fromMap(query.docs.first.data());
    } catch (_) {
      return DemoData.demoOrganization;
    }
  }
}

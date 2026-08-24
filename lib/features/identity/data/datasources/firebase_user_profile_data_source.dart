import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_profile.dart';

class FirebaseUserProfileDataSource {
  final FirebaseFirestore _firestore;

  FirebaseUserProfileDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  Future<void> createUserProfile(UserProfile profile) async {
    final docRef = _usersCollection.doc(profile.uid);
    final data = profile.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return UserProfile.fromMap(doc.data()!);
  }

  Future<UserProfile> updateUserProfile({
    required String uid,
    String? displayName,
    String? phone,
  }) async {
    final docRef = _usersCollection.doc(uid);
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (displayName != null) updates['displayName'] = displayName;
    if (phone != null) updates['phone'] = phone;

    await docRef.update(updates);
    final updatedDoc = await docRef.get();
    if (!updatedDoc.exists || updatedDoc.data() == null) {
      throw Exception('Failed to fetch updated profile.');
    }
    return UserProfile.fromMap(updatedDoc.data()!);
  }
}

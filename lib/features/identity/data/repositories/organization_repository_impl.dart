import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/organization.dart';
import '../../domain/failures/identity_failure.dart';
import '../../domain/repositories/organization_repository.dart';
import '../datasources/firebase_organization_data_source.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  final FirebaseOrganizationDataSource _dataSource;

  OrganizationRepositoryImpl({
    required FirebaseOrganizationDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<Organization?> getOrganizationById(String id) async {
    try {
      if (id.trim().isEmpty) {
        throw const OrganizationValidationFailure(
            'Organization ID cannot be empty.');
      }
      return await _dataSource.getOrganizationById(id);
    } on IdentityFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownIdentityFailure(e.toString());
    }
  }

  @override
  Future<Organization?> getOrganizationByCode(String code) async {
    try {
      if (code.trim().isEmpty) {
        throw const OrganizationValidationFailure(
            'Organization code cannot be empty.');
      }
      return await _dataSource.getOrganizationByCode(code);
    } on IdentityFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownIdentityFailure(e.toString());
    }
  }

  IdentityFailure _mapFirebaseException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const PermissionDeniedFailure();
      case 'not-found':
        return const OrganizationNotFoundFailure();
      case 'unavailable':
        return const FirestoreFailure(
          'Database is temporarily unavailable. Check network connectivity.',
        );
      default:
        return FirestoreFailure(e.message ?? 'Firestore error occurred.');
    }
  }
}

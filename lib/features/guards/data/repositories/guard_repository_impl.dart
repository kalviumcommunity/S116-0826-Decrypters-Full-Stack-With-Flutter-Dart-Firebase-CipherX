import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/guard.dart';
import '../../domain/failures/guard_failure.dart';
import '../../domain/repositories/guard_repository.dart';
import '../../domain/validators/guard_validator.dart';
import '../datasources/firebase_guard_data_source.dart';

class GuardRepositoryImpl implements GuardRepository {
  final FirebaseGuardDataSource _dataSource;

  GuardRepositoryImpl({
    required FirebaseGuardDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<Guard> createGuard(Guard guard) async {
    try {
      final normalized = GuardValidator.validate(guard);
      return await _dataSource.createGuard(normalized);
    } on GuardFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownGuardFailure(e.toString());
    }
  }

  @override
  Future<Guard?> getGuard({
    required String organizationId,
    required String guardId,
  }) async {
    try {
      if (organizationId.trim().isEmpty) {
        throw const GuardValidationFailure('Organization ID cannot be empty.');
      }
      if (guardId.trim().isEmpty) {
        throw const GuardValidationFailure('Guard ID cannot be empty.');
      }
      return await _dataSource.getGuard(
        organizationId: organizationId.trim(),
        guardId: guardId.trim(),
      );
    } on GuardFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownGuardFailure(e.toString());
    }
  }

  @override
  Future<List<Guard>> getGuards(
    String organizationId, {
    bool includeInactive = false,
  }) async {
    try {
      if (organizationId.trim().isEmpty) {
        throw const GuardValidationFailure('Organization ID cannot be empty.');
      }
      return await _dataSource.getGuards(
        organizationId.trim(),
        includeInactive: includeInactive,
      );
    } on GuardFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownGuardFailure(e.toString());
    }
  }

  @override
  Stream<List<Guard>> watchGuards(
    String organizationId, {
    bool includeInactive = false,
  }) {
    if (organizationId.trim().isEmpty) {
      throw const GuardValidationFailure('Organization ID cannot be empty.');
    }
    return _dataSource
        .watchGuards(
      organizationId.trim(),
      includeInactive: includeInactive,
    )
        .handleError((e) {
      if (e is FirebaseException) {
        throw _mapFirebaseException(e);
      }
      throw UnknownGuardFailure(e.toString());
    });
  }

  @override
  Future<Guard> updateGuard(Guard guard) async {
    try {
      if (guard.guardId.trim().isEmpty) {
        throw const GuardValidationFailure('Guard ID cannot be empty.');
      }
      final normalized = GuardValidator.validate(guard);
      return await _dataSource.updateGuard(normalized);
    } on GuardFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownGuardFailure(e.toString());
    }
  }

  @override
  Future<Guard> updateGuardStatus({
    required String organizationId,
    required String guardId,
    required GuardStatus status,
  }) async {
    try {
      if (organizationId.trim().isEmpty) {
        throw const GuardValidationFailure('Organization ID cannot be empty.');
      }
      if (guardId.trim().isEmpty) {
        throw const GuardValidationFailure('Guard ID cannot be empty.');
      }
      return await _dataSource.updateGuardStatus(
        organizationId: organizationId.trim(),
        guardId: guardId.trim(),
        status: status,
      );
    } on GuardFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownGuardFailure(e.toString());
    }
  }

  @override
  Future<void> deleteGuard({
    required String organizationId,
    required String guardId,
  }) async {
    try {
      if (organizationId.trim().isEmpty) {
        throw const GuardValidationFailure('Organization ID cannot be empty.');
      }
      if (guardId.trim().isEmpty) {
        throw const GuardValidationFailure('Guard ID cannot be empty.');
      }
      await _dataSource.deleteGuard(
        organizationId: organizationId.trim(),
        guardId: guardId.trim(),
      );
    } on GuardFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownGuardFailure(e.toString());
    }
  }

  GuardFailure _mapFirebaseException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const PermissionDeniedFailure();
      case 'not-found':
        return const GuardNotFoundFailure();
      case 'unavailable':
        return const FirestoreFailure(
          'Database is temporarily unavailable. Check network connectivity.',
        );
      default:
        return FirestoreFailure(e.message ?? 'Firestore error occurred.');
    }
  }
}

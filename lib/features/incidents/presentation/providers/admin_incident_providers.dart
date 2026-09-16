import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../identity/domain/entities/user_profile.dart';
import '../../../identity/presentation/providers/identity_providers.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/incident_status.dart';
import '../../domain/failures/incident_failure.dart';
import '../../domain/validators/incident_validator.dart';
import 'incident_providers.dart';

/// Currently selected incident status filter for admin views.
/// `null` represents all statuses.
final adminIncidentFilterProvider =
    StateProvider<IncidentStatus?>((ref) => null);

/// Real-time stream of incidents for the authenticated admin's organization,
/// filtered deterministically by [adminIncidentFilterProvider] and ordered newest first.
final adminIncidentsStreamProvider =
    StreamProvider.autoDispose<List<Incident>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null || profile.organizationId.trim().isEmpty) {
    return Stream.value([]);
  }

  // RBAC enforcement: Only admin and supervisor can access organization incidents
  if (profile.role != UserRole.admin && profile.role != UserRole.supervisor) {
    return Stream.value([]);
  }

  final selectedStatus = ref.watch(adminIncidentFilterProvider);
  final repository = ref.watch(incidentRepositoryProvider);

  return repository.watchIncidentsByOrganization(
    profile.organizationId.trim(),
    status: selectedStatus,
  );
});

/// Real-time stream provider for a single incident's details by [incidentId].
final adminIncidentDetailStreamProvider =
    StreamProvider.autoDispose.family<Incident?, String>((ref, incidentId) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null ||
      profile.organizationId.trim().isEmpty ||
      incidentId.trim().isEmpty) {
    return Stream.value(null);
  }

  if (profile.role != UserRole.admin && profile.role != UserRole.supervisor) {
    return Stream.value(null);
  }

  final repository = ref.watch(incidentRepositoryProvider);
  return repository
      .watchIncidentsByOrganization(profile.organizationId.trim())
      .map((incidents) {
    try {
      return incidents.firstWhere((inc) => inc.incidentId == incidentId);
    } catch (_) {
      return null;
    }
  });
});

/// Immutable state for admin incident lifecycle mutations (status updates & resolution).
class AdminIncidentActionState {
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;
  final IncidentStatus? lastUpdatedStatus;

  const AdminIncidentActionState({
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,
    this.lastUpdatedStatus,
  });

  AdminIncidentActionState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool? isSuccess,
    IncidentStatus? lastUpdatedStatus,
    bool clearError = false,
  }) {
    return AdminIncidentActionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
      lastUpdatedStatus: lastUpdatedStatus ?? this.lastUpdatedStatus,
    );
  }
}

/// Controller orchestrating status transitions, resolution workflow, concurrency guards,
/// and RBAC checks for incident management operations.
class AdminIncidentActionController
    extends StateNotifier<AdminIncidentActionState> {
  final Ref _ref;

  AdminIncidentActionController(this._ref)
      : super(const AdminIncidentActionState());

  /// Advances an incident status (e.g. OPEN -> INVESTIGATING).
  ///
  /// Prevents concurrent duplicate submissions and validates RBAC permissions.
  Future<bool> updateStatus({
    required String incidentId,
    required IncidentStatus newStatus,
  }) async {
    if (state.isSubmitting) return false;

    state =
        state.copyWith(isSubmitting: true, clearError: true, isSuccess: false);

    try {
      final profile = _ref.read(currentUserProfileProvider).asData?.value;
      if (profile == null || profile.organizationId.trim().isEmpty) {
        throw const UnauthorizedIncidentActionFailure(
          'Authentication required to perform incident status update.',
        );
      }

      if (profile.role != UserRole.admin &&
          profile.role != UserRole.supervisor) {
        throw const UnauthorizedIncidentActionFailure(
          'Insufficient permissions. Only admins and supervisors may change incident status.',
        );
      }

      final repository = _ref.read(incidentRepositoryProvider);
      await repository.updateIncidentStatus(
        organizationId: profile.organizationId.trim(),
        incidentId: incidentId.trim(),
        status: newStatus,
      );

      state = state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        lastUpdatedStatus: newStatus,
      );
      return true;
    } on IncidentFailure catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
        isSuccess: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to update incident status: $e',
        isSuccess: false,
      );
      return false;
    }
  }

  /// Resolves an incident with mandatory resolution notes and resolver audit trail.
  ///
  /// Enforces:
  /// - Admin or Supervisor authorization
  /// - Non-empty, non-whitespace resolution text
  /// - Automatic resolver identity attribution from authenticated profile
  /// - Server timestamp attribution
  Future<bool> resolveIncident({
    required String incidentId,
    required String resolutionText,
  }) async {
    if (state.isSubmitting) return false;

    // Validate resolution text up-front
    final resolutionValidationError =
        IncidentValidator.validateResolution(resolutionText);
    if (resolutionValidationError != null) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: resolutionValidationError,
        isSuccess: false,
      );
      return false;
    }

    state =
        state.copyWith(isSubmitting: true, clearError: true, isSuccess: false);

    try {
      final profile = _ref.read(currentUserProfileProvider).asData?.value;
      if (profile == null || profile.organizationId.trim().isEmpty) {
        throw const UnauthorizedIncidentActionFailure(
          'Authentication required to resolve incident.',
        );
      }

      if (profile.role != UserRole.admin &&
          profile.role != UserRole.supervisor) {
        throw const UnauthorizedIncidentActionFailure(
          'Insufficient permissions. Only admins and supervisors may resolve incidents.',
        );
      }

      final repository = _ref.read(incidentRepositoryProvider);
      await repository.updateIncidentStatus(
        organizationId: profile.organizationId.trim(),
        incidentId: incidentId.trim(),
        status: IncidentStatus.resolved,
        resolvedBy: profile.uid.trim(),
        resolution: resolutionText.trim(),
      );

      state = state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        lastUpdatedStatus: IncidentStatus.resolved,
      );
      return true;
    } on IncidentFailure catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
        isSuccess: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to resolve incident: $e',
        isSuccess: false,
      );
      return false;
    }
  }

  /// Resets the controller state.
  void reset() {
    state = const AdminIncidentActionState();
  }
}

/// Provider for [AdminIncidentActionController].
final adminIncidentActionControllerProvider = StateNotifierProvider.autoDispose<
    AdminIncidentActionController, AdminIncidentActionState>((ref) {
  return AdminIncidentActionController(ref);
});

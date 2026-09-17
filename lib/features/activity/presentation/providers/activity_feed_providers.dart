import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../alerts/domain/entities/alert.dart';
import '../../../alerts/presentation/providers/alert_providers.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../identity/presentation/providers/identity_providers.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/providers/incident_providers.dart';
import '../../data/datasources/firebase_activity_data_source.dart';
import '../../data/repositories/activity_repository_impl.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/activity_repository.dart';

final activityDataSourceProvider = Provider<FirebaseActivityDataSource>((ref) {
  final firestore = ref.watch(cloudFirestoreProvider);
  return FirebaseActivityDataSource(firestore: firestore);
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final dataSource = ref.watch(activityDataSourceProvider);
  return ActivityRepositoryImpl(dataSource: dataSource);
});

/// Streams the 10 most recent operational alerts for the active organization.
final recentAlertsFeedProvider = StreamProvider.autoDispose<List<Alert>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null || profile.organizationId.trim().isEmpty) {
    return Stream.value([]);
  }

  final repository = ref.watch(alertRepositoryProvider);
  return repository
      .watchAlerts(organizationId: profile.organizationId.trim())
      .map((alerts) {
    final list = List<Alert>.from(alerts);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(10).toList();
  });
});

/// Streams the 10 most recent incidents for the active organization.
final recentIncidentsFeedProvider =
    StreamProvider.autoDispose<List<Incident>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null || profile.organizationId.trim().isEmpty) {
    return Stream.value([]);
  }

  final repository = ref.watch(incidentRepositoryProvider);
  return repository
      .watchIncidentsByOrganization(profile.organizationId.trim())
      .map((incidents) {
    final list = List<Incident>.from(incidents);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(10).toList();
  });
});

/// Streams the 10 most recent attendance entries for the active organization.
final recentAttendanceFeedProvider =
    StreamProvider.autoDispose<List<AttendanceRecord>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null || profile.organizationId.trim().isEmpty) {
    return Stream.value([]);
  }

  final repository = ref.watch(attendanceRepositoryProvider);
  return repository
      .watchAttendanceByOrganization(profile.organizationId.trim())
      .map((records) {
    final list = List<AttendanceRecord>.from(records);
    list.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
    return list.take(10).toList();
  });
});

/// Streams the 10 most recent system audit logs for the active organization.
final recentAuditActivityProvider =
    StreamProvider.autoDispose<List<AuditLog>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null || profile.organizationId.trim().isEmpty) {
    return Stream.value([]);
  }

  final repository = ref.watch(activityRepositoryProvider);
  return repository.watchRecentAuditLogs(
    organizationId: profile.organizationId.trim(),
    limit: 10,
  );
});

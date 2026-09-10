import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../identity/presentation/providers/identity_providers.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/providers/incident_providers.dart';
import '../../data/datasources/firebase_activity_data_source.dart';
import '../../data/repositories/activity_repository_impl.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/entities/operational_alert.dart';
import '../../domain/repositories/activity_repository.dart';

final activityDataSourceProvider = Provider<FirebaseActivityDataSource>((ref) {
  return FirebaseActivityDataSource();
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final dataSource = ref.watch(activityDataSourceProvider);
  return ActivityRepositoryImpl(dataSource: dataSource);
});

final recentAlertsFeedProvider =
    StreamProvider.autoDispose<List<OperationalAlert>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null || profile.organizationId.trim().isEmpty) {
    return Stream.value([]);
  }

  final repository = ref.watch(activityRepositoryProvider);
  return repository.watchRecentAlerts(
    organizationId: profile.organizationId,
    limit: 10,
  );
});

final recentIncidentsFeedProvider =
    StreamProvider.autoDispose<List<Incident>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null || profile.organizationId.trim().isEmpty) {
    return Stream.value([]);
  }

  final repository = ref.watch(incidentRepositoryProvider);
  return repository.watchIncidentsByGuard(
    organizationId: profile.organizationId,
    guardId: profile.uid,
  );
});

final recentAttendanceFeedProvider =
    StreamProvider.autoDispose<List<AttendanceRecord>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null || profile.organizationId.trim().isEmpty) {
    return Stream.value([]);
  }

  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.watchAttendanceHistoryForGuard(
    organizationId: profile.organizationId,
    guardId: profile.uid,
  );
});

final recentAuditActivityProvider =
    StreamProvider.autoDispose<List<AuditLog>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null || profile.organizationId.trim().isEmpty) {
    return Stream.value([]);
  }

  final repository = ref.watch(activityRepositoryProvider);
  return repository.watchRecentAuditLogs(
    organizationId: profile.organizationId,
    limit: 10,
  );
});

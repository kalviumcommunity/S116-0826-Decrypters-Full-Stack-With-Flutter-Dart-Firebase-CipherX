import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/firebase_alert_data_source.dart';
import '../../data/repositories/alert_repository_impl.dart';
import '../../domain/entities/alert.dart';
import '../../domain/policies/late_check_in_policy.dart';
import '../../domain/policies/missed_shift_policy.dart';
import '../../domain/policies/site_coverage_provider.dart';
import '../../domain/repositories/alert_repository.dart';
import '../../domain/services/alert_engine.dart';
import '../../domain/services/clock.dart';
import '../../domain/services/notification_adapter.dart';

final alertDataSourceProvider = Provider<FirebaseAlertDataSource>((ref) {
  return FirebaseAlertDataSource();
});

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  final ds = ref.watch(alertDataSourceProvider);
  return AlertRepositoryImpl(dataSource: ds);
});

final clockProvider = Provider<Clock>((ref) {
  return const SystemClock();
});

final notificationAdapterProvider = Provider<NotificationAdapter>((ref) {
  return LoggingNotificationAdapter();
});

final missedShiftPolicyProvider = Provider<MissedShiftPolicy>((ref) {
  return const DefaultMissedShiftPolicy();
});

final lateCheckInPolicyProvider = Provider<LateCheckInPolicy>((ref) {
  return const DefaultLateCheckInPolicy();
});

final siteCoverageProviderProvider = Provider<SiteCoverageProvider>((ref) {
  return const StaticSiteCoverageProvider();
});

final alertEngineProvider = Provider<AlertEngine>((ref) {
  return AlertEngine(
    repository: ref.watch(alertRepositoryProvider),
    notificationAdapter: ref.watch(notificationAdapterProvider),
    clock: ref.watch(clockProvider),
    missedShiftPolicy: ref.watch(missedShiftPolicyProvider),
    lateCheckInPolicy: ref.watch(lateCheckInPolicyProvider),
    siteCoverageProvider: ref.watch(siteCoverageProviderProvider),
  );
});

final organizationAlertsStreamProvider =
    StreamProvider.family<List<Alert>, String>((ref, organizationId) {
  final repo = ref.watch(alertRepositoryProvider);
  return repo.watchAlerts(organizationId: organizationId);
});

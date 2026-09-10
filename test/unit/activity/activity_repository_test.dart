import 'package:cipher_x/features/activity/data/repositories/activity_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityRepositoryImpl Unit Tests', () {
    test('getRecentAlerts returns empty list for empty parameters', () async {
      final repository = ActivityRepositoryImpl();
      final result = await repository.getRecentAlerts(
        organizationId: '',
      );

      expect(result, isEmpty);
    });

    test('watchRecentAlerts returns empty list stream for empty parameters',
        () async {
      final repository = ActivityRepositoryImpl();
      final stream = repository.watchRecentAlerts(
        organizationId: '',
      );

      expect(await stream.first, isEmpty);
    });

    test('getRecentAuditLogs returns empty list for empty parameters',
        () async {
      final repository = ActivityRepositoryImpl();
      final result = await repository.getRecentAuditLogs(
        organizationId: '',
      );

      expect(result, isEmpty);
    });

    test('watchRecentAuditLogs returns empty list stream for empty parameters',
        () async {
      final repository = ActivityRepositoryImpl();
      final stream = repository.watchRecentAuditLogs(
        organizationId: '',
      );

      expect(await stream.first, isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/core/services/fcm_service.dart';
import 'package:cipher_x/features/alerts/data/services/fcm_notification_adapter.dart';
import 'package:cipher_x/features/alerts/domain/entities/alert.dart';
import 'package:cipher_x/features/alerts/domain/entities/alert_status.dart';
import 'package:cipher_x/features/alerts/domain/entities/alert_type.dart';

void main() {
  group('DeviceToken Unit Tests', () {
    test('DeviceToken serializes to Firestore correctly', () {
      final tNow = DateTime(2026, 9, 23, 12, 0, 0);
      final token = DeviceToken(
        deviceId: 'dev_android_usr123',
        userId: 'usr123',
        organizationId: 'org_test',
        fcmToken: 'fcm_token_xyz_987',
        platform: 'android',
        role: 'admin',
        enabled: true,
        createdAt: tNow,
      );

      final map = token.toFirestore();

      expect(map['deviceId'], 'dev_android_usr123');
      expect(map['userId'], 'usr123');
      expect(map['organizationId'], 'org_test');
      expect(map['fcmToken'], 'fcm_token_xyz_987');
      expect(map['platform'], 'android');
      expect(map['role'], 'admin');
      expect(map['enabled'], true);
    });

    test('DeviceToken deserializes from Firestore map correctly', () {
      final map = <String, dynamic>{
        'deviceId': 'dev_android_usr456',
        'userId': 'usr456',
        'organizationId': 'org_omega',
        'fcmToken': 'fcm_token_abc_123',
        'platform': 'android',
        'role': 'supervisor',
        'enabled': true,
      };

      final token = DeviceToken.fromFirestore(map);

      expect(token.deviceId, 'dev_android_usr456');
      expect(token.userId, 'usr456');
      expect(token.organizationId, 'org_omega');
      expect(token.fcmToken, 'fcm_token_abc_123');
      expect(token.platform, 'android');
      expect(token.role, 'supervisor');
      expect(token.enabled, true);
    });
  });

  group('FcmNotificationAdapter Unit Tests', () {
    test('notify executes cleanly for critical incident alert candidate', () async {
      final adapter = FcmNotificationAdapter();
      final alert = Alert(
        alertId: 'alt_999',
        organizationId: 'org_omega',
        type: AlertType.criticalIncident,
        sourceEntityId: 'inc_555',
        sourceEntityType: 'incident',
        status: AlertStatus.active,
        createdAt: DateTime.now(),
        metadata: const {'message': 'Fire reported near east gate'},
      );

      expect(() async => await adapter.notify(alert), returnsNormally);
    });
  });
}

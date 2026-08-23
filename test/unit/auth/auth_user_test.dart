import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/auth/domain/entities/auth_user.dart';

void main() {
  group('AuthUser Unit Tests', () {
    test('instantiates cleanly with required fields and defaults', () {
      const user = AuthUser(uid: 'user_123', email: 'guard@cipherx.com');

      expect(user.uid, equals('user_123'));
      expect(user.email, equals('guard@cipherx.com'));
      expect(user.displayName, isNull);
      expect(user.photoUrl, isNull);
      expect(user.emailVerified, isFalse);
    });

    test('supports value equality and hashCode', () {
      const user1 = AuthUser(
        uid: 'user_123',
        email: 'guard@cipherx.com',
        displayName: 'Guard John',
        emailVerified: true,
      );

      const user2 = AuthUser(
        uid: 'user_123',
        email: 'guard@cipherx.com',
        displayName: 'Guard John',
        emailVerified: true,
      );

      const user3 = AuthUser(
        uid: 'user_456',
        email: 'guard2@cipherx.com',
      );

      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
      expect(user1, isNot(equals(user3)));
    });

    test('toString formats fields correctly', () {
      const user = AuthUser(
        uid: 'user_123',
        email: 'guard@cipherx.com',
        emailVerified: true,
      );

      expect(
        user.toString(),
        contains('user_123'),
      );
      expect(
        user.toString(),
        contains('guard@cipherx.com'),
      );
    });
  });
}

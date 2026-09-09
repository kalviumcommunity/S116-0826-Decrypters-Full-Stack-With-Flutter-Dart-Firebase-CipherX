import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QR Domain Architectural Purity Tests', () {
    test('domain files must not depend on UI packages, Riverpod, or Firebase',
        () {
      final domainDir = Directory('lib/features/qr/domain');
      expect(domainDir.existsSync(), isTrue,
          reason: 'QR domain directory must exist');

      final forbiddenPatterns = [
        'package:flutter/',
        'package:flutter_riverpod/',
        'package:mobile_scanner/',
        'package:qr_flutter/',
        'package:cloud_firestore/',
        'package:firebase_core/',
        'package:firebase_auth/',
      ];

      final dartFiles = domainDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        for (final forbidden in forbiddenPatterns) {
          expect(
            content.contains(forbidden),
            isFalse,
            reason:
                'Domain file ${file.path} contains forbidden import "$forbidden"',
          );
        }
      }
    });
  });
}

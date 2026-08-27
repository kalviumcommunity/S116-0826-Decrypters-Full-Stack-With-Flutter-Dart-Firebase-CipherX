import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Shift Domain Architectural Purity Tests', () {
    test('Shift Domain does not import forbidden packages', () {
      final domainDir = Directory('lib/features/shifts/domain');
      expect(domainDir.existsSync(), isTrue);

      final files = domainDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final forbiddenImports = [
        'cloud_firestore',
        'firebase_auth',
        'package:flutter/material.dart',
        'package:flutter/widgets.dart',
        'flutter_riverpod',
        'go_router',
      ];

      for (final file in files) {
        final content = file.readAsStringSync();
        for (final forbidden in forbiddenImports) {
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

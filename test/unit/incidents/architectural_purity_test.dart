import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Incident Domain Architectural Purity Tests', () {
    test('Incident Domain does not import forbidden packages', () {
      final domainDir = Directory('lib/features/incidents/domain');
      expect(domainDir.existsSync(), isTrue);

      final files = domainDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final forbiddenImports = [
        'cloud_firestore',
        'firebase_auth',
        'firebase_core',
        'firebase_storage',
        'firebase_messaging',
        'package:flutter/material.dart',
        'package:flutter/widgets.dart',
        'package:flutter/cupertino.dart',
        'flutter_riverpod',
        'go_router',
        'geolocator',
        'mobile_scanner',
      ];

      expect(files, isNotEmpty);

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

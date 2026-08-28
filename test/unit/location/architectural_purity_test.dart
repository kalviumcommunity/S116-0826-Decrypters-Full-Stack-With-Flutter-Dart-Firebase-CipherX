import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Location Domain Architectural Purity Tests', () {
    test(
        'domain files must not depend on Flutter SDK, UI, Riverpod, or geolocator',
        () {
      final domainDir = Directory('lib/features/location/domain');
      expect(domainDir.existsSync(), isTrue);

      final forbiddenImports = [
        'package:flutter/',
        'package:flutter_riverpod/',
        'package:geolocator/',
        'package:go_router/',
        'package:cloud_firestore/',
        'package:firebase_',
      ];

      final files = domainDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (final line in lines) {
          if (line.trim().startsWith('import ')) {
            for (final forbidden in forbiddenImports) {
              expect(
                line.contains(forbidden),
                isFalse,
                reason:
                    'Forbidden import "$forbidden" found in domain file: ${file.path}',
              );
            }
          }
        }
      }
    });
  });
}

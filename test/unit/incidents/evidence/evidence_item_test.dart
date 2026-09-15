import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/incidents/domain/entities/evidence_item.dart';

void main() {
  group('EvidenceItem Entity Tests', () {
    final now = DateTime.utc(2026, 9, 15, 10, 0, 0);

    test('supports serialization toMap and deserialization fromMap', () {
      final item = EvidenceItem(
        evidenceId: 'ev_123',
        incidentId: 'inc_456',
        organizationId: 'org_789',
        storagePath: 'incidents/inc_456/evidence/ev_123.jpg',
        fileName: 'broken_gate.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 2048,
        uploadedBy: 'guard_007',
        createdAt: now,
      );

      final map = item.toMap();
      expect(map['evidenceId'], 'ev_123');
      expect(map['incidentId'], 'inc_456');
      expect(map['organizationId'], 'org_789');
      expect(map['storagePath'], 'incidents/inc_456/evidence/ev_123.jpg');
      expect(map['fileName'], 'broken_gate.jpg');
      expect(map['contentType'], 'image/jpeg');
      expect(map['sizeBytes'], 2048);
      expect(map['uploadedBy'], 'guard_007');

      final fromMap = EvidenceItem.fromMap(map, 'ev_123');
      expect(fromMap.evidenceId, item.evidenceId);
      expect(fromMap.incidentId, item.incidentId);
      expect(fromMap.organizationId, item.organizationId);
      expect(fromMap.storagePath, item.storagePath);
      expect(fromMap.fileName, item.fileName);
      expect(fromMap.contentType, item.contentType);
      expect(fromMap.sizeBytes, item.sizeBytes);
      expect(fromMap.uploadedBy, item.uploadedBy);
      expect(fromMap.createdAt, item.createdAt);
    });

    test('supports value equality', () {
      final item1 = EvidenceItem(
        evidenceId: 'ev_1',
        incidentId: 'inc_1',
        organizationId: 'org_1',
        storagePath: 'path/1',
        fileName: 'a.png',
        contentType: 'image/png',
        sizeBytes: 100,
        uploadedBy: 'u1',
        createdAt: now,
      );

      final item2 = EvidenceItem(
        evidenceId: 'ev_1',
        incidentId: 'inc_1',
        organizationId: 'org_1',
        storagePath: 'path/1',
        fileName: 'a.png',
        contentType: 'image/png',
        sizeBytes: 100,
        uploadedBy: 'u1',
        createdAt: now,
      );

      expect(item1, equals(item2));
      expect(item1.hashCode, equals(item2.hashCode));
    });

    test('copyWith produces updated clone', () {
      final item = EvidenceItem(
        evidenceId: 'ev_1',
        incidentId: 'inc_1',
        organizationId: 'org_1',
        storagePath: 'path/1',
        fileName: 'a.png',
        contentType: 'image/png',
        sizeBytes: 100,
        uploadedBy: 'u1',
        createdAt: now,
      );

      final updated = item.copyWith(sizeBytes: 250);
      expect(updated.sizeBytes, 250);
      expect(updated.evidenceId, item.evidenceId);
    });
  });
}

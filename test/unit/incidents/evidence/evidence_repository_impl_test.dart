import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cipher_x/features/incidents/data/datasources/firebase_evidence_data_source.dart';
import 'package:cipher_x/features/incidents/data/datasources/firebase_storage_evidence_data_source.dart';
import 'package:cipher_x/features/incidents/data/repositories/evidence_repository_impl.dart';
import 'package:cipher_x/features/incidents/domain/entities/evidence_file.dart';
import 'package:cipher_x/features/incidents/domain/entities/evidence_item.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_severity.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_status.dart';
import 'package:cipher_x/features/incidents/domain/failures/evidence_failure.dart';
import 'package:cipher_x/features/incidents/domain/repositories/incident_repository.dart';
import 'package:cipher_x/features/incidents/domain/services/image_compressor.dart';

class MockStorageDataSource extends Mock
    implements FirebaseStorageEvidenceDataSource {}

class MockEvidenceDataSource extends Mock
    implements FirebaseEvidenceDataSource {}

class MockIncidentRepository extends Mock implements IncidentRepository {}

class MockImageCompressor extends Mock implements ImageCompressor {}

void main() {
  late MockStorageDataSource mockStorage;
  late MockEvidenceDataSource mockFirestore;
  late MockIncidentRepository mockIncidentRepo;
  late MockImageCompressor mockCompressor;
  late EvidenceRepositoryImpl repository;

  final sampleJpegBytes = Uint8List.fromList([
    0xFF,
    0xD8,
    0xFF,
    0xE0,
    0x00,
    0x10,
    0x4A,
    0x46,
    ...List.filled(100, 0x55),
  ]);

  final sampleIncident = Incident(
    incidentId: 'inc_001',
    organizationId: 'org_test',
    reportedBy: 'user_1',
    siteId: 'site_1',
    type: 'Theft',
    severity: IncidentSeverity.high,
    description: 'Break-in at front gate',
    status: IncidentStatus.open,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(
      EvidenceItem(
        evidenceId: 'e',
        incidentId: 'i',
        organizationId: 'o',
        storagePath: 'p',
        fileName: 'f',
        contentType: 'c',
        sizeBytes: 1,
        uploadedBy: 'u',
        createdAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockStorage = MockStorageDataSource();
    mockFirestore = MockEvidenceDataSource();
    mockIncidentRepo = MockIncidentRepository();
    mockCompressor = MockImageCompressor();

    repository = EvidenceRepositoryImpl(
      storageDataSource: mockStorage,
      evidenceDataSource: mockFirestore,
      incidentRepository: mockIncidentRepo,
      imageCompressor: mockCompressor,
    );
  });

  group('EvidenceRepositoryImpl - uploadEvidence', () {
    test('successful upload coordinates storage, compression, and firestore',
        () async {
      when(() => mockIncidentRepo.getIncident(
            organizationId: 'org_test',
            incidentId: 'inc_001',
          )).thenAnswer((_) async => sampleIncident);

      when(() => mockCompressor.isCompressible('image/jpeg')).thenReturn(true);
      when(() => mockCompressor.compress(
            bytes: sampleJpegBytes,
            contentType: 'image/jpeg',
          )).thenAnswer((_) async => sampleJpegBytes);

      when(() => mockStorage.uploadBytes(
            storagePath: any(named: 'storagePath'),
            bytes: any(named: 'bytes'),
            contentType: 'image/jpeg',
            customMetadata: any(named: 'customMetadata'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async => 'incidents/inc_001/evidence/file.jpg');

      when(() => mockFirestore.recordEvidence(any())).thenAnswer(
        (invocation) async => invocation.positionalArguments[0] as EvidenceItem,
      );

      final file = EvidenceFile(
        name: 'gate_photo.jpg',
        bytes: sampleJpegBytes,
        contentType: 'image/jpeg',
      );

      double reportedProgress = 0.0;
      final result = await repository.uploadEvidence(
        organizationId: 'org_test',
        incidentId: 'inc_001',
        uploadedBy: 'user_1',
        file: file,
        onProgress: (p, t, tot) {
          reportedProgress = p;
        },
      );

      expect(reportedProgress >= 0.0, isTrue);
      expect(result.incidentId, 'inc_001');
      expect(result.organizationId, 'org_test');
      expect(result.fileName, 'gate_photo.jpg');
      verify(() => mockStorage.uploadBytes(
            storagePath: any(named: 'storagePath'),
            bytes: sampleJpegBytes,
            contentType: 'image/jpeg',
            customMetadata: any(named: 'customMetadata'),
            onProgress: any(named: 'onProgress'),
          )).called(1);
      verify(() => mockFirestore.recordEvidence(any())).called(1);
    });

    test('rejects unauthenticated caller', () async {
      final file = EvidenceFile(
        name: 'photo.jpg',
        bytes: sampleJpegBytes,
        contentType: 'image/jpeg',
      );

      expect(
        () => repository.uploadEvidence(
          organizationId: 'org_test',
          incidentId: 'inc_001',
          uploadedBy: '   ',
          file: file,
        ),
        throwsA(isA<UnauthenticatedFailure>()),
      );
    });

    test('rejects nonexistent incident', () async {
      when(() => mockIncidentRepo.getIncident(
            organizationId: 'org_test',
            incidentId: 'inc_nonexistent',
          )).thenAnswer((_) async => null);

      final file = EvidenceFile(
        name: 'photo.jpg',
        bytes: sampleJpegBytes,
        contentType: 'image/jpeg',
      );

      expect(
        () => repository.uploadEvidence(
          organizationId: 'org_test',
          incidentId: 'inc_nonexistent',
          uploadedBy: 'user_1',
          file: file,
        ),
        throwsA(isA<IncidentNotFoundFailure>()),
      );
    });

    test('rejects cross-organization upload attempt', () async {
      final otherOrgIncident =
          sampleIncident.copyWith(organizationId: 'other_org');
      when(() => mockIncidentRepo.getIncident(
            organizationId: 'org_test',
            incidentId: 'inc_001',
          )).thenAnswer((_) async => otherOrgIncident);

      final file = EvidenceFile(
        name: 'photo.jpg',
        bytes: sampleJpegBytes,
        contentType: 'image/jpeg',
      );

      expect(
        () => repository.uploadEvidence(
          organizationId: 'org_test',
          incidentId: 'inc_001',
          uploadedBy: 'user_1',
          file: file,
        ),
        throwsA(isA<OrganizationMismatchFailure>()),
      );
    });

    test('rolls back uploaded storage object on firestore metadata failure',
        () async {
      when(() => mockIncidentRepo.getIncident(
            organizationId: 'org_test',
            incidentId: 'inc_001',
          )).thenAnswer((_) async => sampleIncident);

      when(() => mockCompressor.isCompressible(any())).thenReturn(false);

      when(() => mockStorage.uploadBytes(
            storagePath: any(named: 'storagePath'),
            bytes: any(named: 'bytes'),
            contentType: any(named: 'contentType'),
            customMetadata: any(named: 'customMetadata'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async => 'incidents/inc_001/evidence/file.jpg');

      when(() => mockStorage.deleteFile(any())).thenAnswer((_) async {});

      when(() => mockFirestore.recordEvidence(any())).thenThrow(
        const PersistenceFailure('Firestore database offline'),
      );

      final file = EvidenceFile(
        name: 'photo.jpg',
        bytes: sampleJpegBytes,
        contentType: 'image/jpeg',
      );

      try {
        await repository.uploadEvidence(
          organizationId: 'org_test',
          incidentId: 'inc_001',
          uploadedBy: 'user_1',
          file: file,
          onProgress: (p, t, tot) {},
        );
        fail('Should have thrown PersistenceFailure');
      } catch (e) {
        expect(e, isA<PersistenceFailure>());
      }

      // Verify that deleteFile was invoked for atomic cleanup!
      verify(() => mockStorage.deleteFile(any())).called(1);
    });
  });
}

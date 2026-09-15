import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';
import 'package:cipher_x/features/identity/presentation/providers/identity_providers.dart';
import 'package:cipher_x/features/incidents/domain/entities/evidence_file.dart';
import 'package:cipher_x/features/incidents/domain/entities/evidence_item.dart';
import 'package:cipher_x/features/incidents/domain/failures/evidence_failure.dart';
import 'package:cipher_x/features/incidents/domain/repositories/evidence_repository.dart';
import 'package:cipher_x/features/incidents/domain/services/image_compressor.dart';
import 'package:cipher_x/features/incidents/presentation/providers/evidence_providers.dart';

class MockEvidenceRepository extends Mock implements EvidenceRepository {}

class MockImageCompressor extends Mock implements ImageCompressor {}

void main() {
  late MockEvidenceRepository mockRepo;
  late MockImageCompressor mockCompressor;
  late ProviderContainer container;

  final sampleBytes = Uint8List.fromList([
    0xFF,
    0xD8,
    0xFF,
    0xE0,
    0x00,
    0x10,
    0x4A,
    0x46,
    ...List.filled(50, 0x11),
  ]);

  final sampleFile = EvidenceFile(
    name: 'test_evidence.jpg',
    bytes: sampleBytes,
    contentType: 'image/jpeg',
  );

  final sampleUser = UserProfile(
    uid: 'guard_123',
    email: 'guard@cipherx.com',
    displayName: 'Officer John',
    phone: '+1234567890',
    organizationId: 'org_alpha',
    role: UserRole.guard,
    status: UserStatus.active,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(sampleFile);
  });

  setUp(() {
    mockRepo = MockEvidenceRepository();
    mockCompressor = MockImageCompressor();

    when(() => mockCompressor.isCompressible(any())).thenReturn(true);

    container = ProviderContainer(
      overrides: [
        currentUserProfileProvider.overrideWithValue(AsyncData(sampleUser)),
        evidenceRepositoryProvider.overrideWithValue(mockRepo),
        imageCompressorProvider.overrideWithValue(mockCompressor),
      ],
    );
    // Keep autoDispose controller alive during tests
    container.listen(evidenceUploadControllerProvider, (_, __) {});
  });

  tearDown(() => container.dispose());

  group('EvidenceUploadController Tests', () {
    test('initial state is idle with 0 progress', () {
      final state = container.read(evidenceUploadControllerProvider);
      expect(state.status, EvidenceUploadStatus.idle);
      expect(state.progress, 0.0);
      expect(state.isUploading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('successful upload completes with success state and progress 1.0',
        () async {
      final uploadedItem = EvidenceItem(
        evidenceId: 'ev_1',
        incidentId: 'inc_1',
        organizationId: 'org_alpha',
        storagePath: 'incidents/inc_1/evidence/ev_1.jpg',
        fileName: 'test_evidence.jpg',
        contentType: 'image/jpeg',
        sizeBytes: sampleBytes.length,
        uploadedBy: 'guard_123',
        createdAt: DateTime.now(),
      );

      when(() => mockRepo.uploadEvidence(
            organizationId: 'org_alpha',
            incidentId: 'inc_1',
            uploadedBy: 'guard_123',
            file: any(named: 'file'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async => uploadedItem);

      final controller =
          container.read(evidenceUploadControllerProvider.notifier);
      final success = await controller.uploadEvidence(
        incidentId: 'inc_1',
        file: sampleFile,
      );

      expect(success, isTrue);
      final finalState = container.read(evidenceUploadControllerProvider);
      expect(finalState.status, EvidenceUploadStatus.success);
      expect(finalState.progress, 1.0);
      expect(finalState.uploadedItem, uploadedItem);
      expect(finalState.errorMessage, isNull);
    });

    test('duplicate upload call while active is rejected', () async {
      when(() => mockRepo.uploadEvidence(
            organizationId: any(named: 'organizationId'),
            incidentId: any(named: 'incidentId'),
            uploadedBy: any(named: 'uploadedBy'),
            file: any(named: 'file'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return EvidenceItem(
          evidenceId: 'e',
          incidentId: 'i',
          organizationId: 'o',
          storagePath: 'p',
          fileName: 'f',
          contentType: 'c',
          sizeBytes: 1,
          uploadedBy: 'u',
          createdAt: DateTime.now(),
        );
      });

      final controller =
          container.read(evidenceUploadControllerProvider.notifier);
      final firstCall =
          controller.uploadEvidence(incidentId: 'inc_1', file: sampleFile);
      final secondCall =
          controller.uploadEvidence(incidentId: 'inc_1', file: sampleFile);

      final secondResult = await secondCall;
      expect(secondResult, isFalse); // Guarded against duplicate upload!

      final firstResult = await firstCall;
      expect(firstResult, isTrue);
    });

    test('failure maps typed error to state message and allows safe retry',
        () async {
      when(() => mockRepo.uploadEvidence(
            organizationId: any(named: 'organizationId'),
            incidentId: any(named: 'incidentId'),
            uploadedBy: any(named: 'uploadedBy'),
            file: any(named: 'file'),
            onProgress: any(named: 'onProgress'),
          )).thenThrow(const FileTooLargeFailure());

      final controller =
          container.read(evidenceUploadControllerProvider.notifier);
      final success = await controller.uploadEvidence(
        incidentId: 'inc_1',
        file: sampleFile,
      );

      expect(success, isFalse);
      final errorState = container.read(evidenceUploadControllerProvider);
      expect(errorState.status, EvidenceUploadStatus.failure);
      expect(errorState.errorMessage, contains('10 MB'));

      // Retry
      when(() => mockRepo.uploadEvidence(
            organizationId: any(named: 'organizationId'),
            incidentId: any(named: 'incidentId'),
            uploadedBy: any(named: 'uploadedBy'),
            file: any(named: 'file'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async => EvidenceItem(
            evidenceId: 'e2',
            incidentId: 'inc_1',
            organizationId: 'org_alpha',
            storagePath: 'p',
            fileName: 'f',
            contentType: 'c',
            sizeBytes: 1,
            uploadedBy: 'u',
            createdAt: DateTime.now(),
          ));

      final retrySuccess = await controller.retry(
        incidentId: 'inc_1',
        file: sampleFile,
      );
      expect(retrySuccess, isTrue);
      expect(container.read(evidenceUploadControllerProvider).status,
          EvidenceUploadStatus.success);
    });
  });
}

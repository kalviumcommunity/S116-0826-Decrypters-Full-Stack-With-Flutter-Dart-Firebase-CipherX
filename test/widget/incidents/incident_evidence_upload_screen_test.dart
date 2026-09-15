import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';
import 'package:cipher_x/features/identity/presentation/providers/identity_providers.dart';
import 'package:cipher_x/features/incidents/presentation/providers/evidence_providers.dart';
import 'package:cipher_x/features/incidents/presentation/screens/incident_evidence_upload_screen.dart';

void main() {
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

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        currentUserProfileProvider.overrideWithValue(AsyncData(sampleUser)),
        incidentEvidenceListProvider('test_inc_123')
            .overrideWith((ref) => Stream.value([])),
      ],
      child: const MaterialApp(
        home: IncidentEvidenceUploadScreen(incidentId: 'test_inc_123'),
      ),
    );
  }

  testWidgets(
      'IncidentEvidenceUploadScreen renders context banner and action chips',
      (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Incident Evidence'), findsOneWidget);
    expect(find.textContaining('Incident ID: test_inc_123'), findsOneWidget);
    expect(find.text('Select Evidence to Attach'), findsOneWidget);
    expect(find.text('Add JPEG Photo'), findsOneWidget);
    expect(find.text('Add PNG Image'), findsOneWidget);
    expect(find.text('Add PDF Document'), findsOneWidget);
    expect(find.text('Upload Evidence'), findsOneWidget);
  });

  testWidgets('Selecting an action chip shows preview card', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add JPEG Photo'));
    await tester.pumpAndSettle();

    expect(find.text('incident_photo.jpg'), findsOneWidget);
    expect(find.textContaining('image/jpeg'), findsOneWidget);
  });
}

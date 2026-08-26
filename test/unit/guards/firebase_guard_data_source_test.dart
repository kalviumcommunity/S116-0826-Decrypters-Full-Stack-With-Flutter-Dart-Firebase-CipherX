// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cipher_x/features/guards/data/datasources/firebase_guard_data_source.dart';
import 'package:cipher_x/features/guards/domain/entities/guard.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockOrgCollection;
  late MockDocumentReference mockOrgDoc;
  late MockCollectionReference mockGuardsCollection;
  late MockDocumentReference mockGuardDoc;
  late MockDocumentSnapshot mockGuardSnapshot;
  late MockQuerySnapshot mockQuerySnapshot;
  late FirebaseGuardDataSource dataSource;

  final tMapData = <String, dynamic>{
    'guardId': 'guard_101',
    'organizationId': 'org_abc',
    'name': 'John Officer',
    'employeeId': 'EMP-101',
    'phone': '+1 555-0199',
    'email': 'john@cipherx.com',
    'status': 'active',
  };

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockOrgCollection = MockCollectionReference();
    mockOrgDoc = MockDocumentReference();
    mockGuardsCollection = MockCollectionReference();
    mockGuardDoc = MockDocumentReference();
    mockGuardSnapshot = MockDocumentSnapshot();
    mockQuerySnapshot = MockQuerySnapshot();

    dataSource = FirebaseGuardDataSource(firestore: mockFirestore);

    when(() => mockFirestore.collection('organizations'))
        .thenReturn(mockOrgCollection);
    when(() => mockOrgCollection.doc(any())).thenReturn(mockOrgDoc);
    when(() => mockOrgDoc.collection('guards'))
        .thenReturn(mockGuardsCollection);
  });

  group('FirebaseGuardDataSource Unit Tests', () {
    test('getGuard returns Guard entity when document exists', () async {
      when(() => mockGuardsCollection.doc('guard_101'))
          .thenReturn(mockGuardDoc);
      when(() => mockGuardDoc.get()).thenAnswer((_) async => mockGuardSnapshot);
      when(() => mockGuardSnapshot.exists).thenReturn(true);
      when(() => mockGuardSnapshot.data()).thenReturn(tMapData);

      final result = await dataSource.getGuard(
        organizationId: 'org_abc',
        guardId: 'guard_101',
      );

      expect(result, isNotNull);
      expect(result?.guardId, equals('guard_101'));
      expect(result?.name, equals('John Officer'));
    });

    test('getGuard returns null when document does not exist', () async {
      when(() => mockGuardsCollection.doc('guard_101'))
          .thenReturn(mockGuardDoc);
      when(() => mockGuardDoc.get()).thenAnswer((_) async => mockGuardSnapshot);
      when(() => mockGuardSnapshot.exists).thenReturn(false);

      final result = await dataSource.getGuard(
        organizationId: 'org_abc',
        guardId: 'guard_101',
      );

      expect(result, isNull);
    });

    test('getGuards returns list of Guards from query snapshot', () async {
      final mockDoc = MockQueryDocumentSnapshot();
      when(() => mockGuardsCollection.get())
          .thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([mockDoc]);
      when(() => mockDoc.data()).thenReturn(tMapData);

      final result = await dataSource.getGuards('org_abc');

      expect(result, hasLength(1));
      expect(result.first.guardId, equals('guard_101'));
    });

    test(
        'updateGuardStatus throws FirebaseException when doc is missing after update',
        () async {
      when(() => mockGuardsCollection.doc('guard_101'))
          .thenReturn(mockGuardDoc);
      when(() => mockGuardDoc.update(any())).thenAnswer((_) async {});
      when(() => mockGuardDoc.get()).thenAnswer((_) async => mockGuardSnapshot);
      when(() => mockGuardSnapshot.exists).thenReturn(false);

      expect(
        () => dataSource.updateGuardStatus(
          organizationId: 'org_abc',
          guardId: 'guard_101',
          status: GuardStatus.inactive,
        ),
        throwsA(isA<FirebaseException>()
            .having((e) => e.code, 'code', 'not-found')),
      );
    });
  });
}

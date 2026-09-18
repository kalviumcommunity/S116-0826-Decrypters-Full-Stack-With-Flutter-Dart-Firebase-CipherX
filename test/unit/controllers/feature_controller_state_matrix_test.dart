import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Feature Controller & AsyncValue State Lifecycle Matrix Tests', () {
    test('1. AsyncValue transitions: uninitialized -> loading -> data', () {
      AsyncValue<List<String>> state = const AsyncValue.loading();
      expect(state.isLoading, isTrue);
      expect(state.hasValue, isFalse);
      expect(state.hasError, isFalse);

      final items = ['Site Alpha', 'Site Beta'];
      state = AsyncValue.data(items);
      expect(state.isLoading, isFalse);
      expect(state.hasValue, isTrue);
      expect(state.value, equals(items));
    });

    test('2. AsyncValue transitions: loading -> error -> retry (loading) -> data', () {
      AsyncValue<int> state = const AsyncValue.loading();
      expect(state.isLoading, isTrue);

      final exception = Exception('Firestore connection timeout');
      state = AsyncValue.error(exception, StackTrace.current);
      expect(state.hasError, isTrue);
      expect(state.error, equals(exception));

      // Retry triggered
      state = const AsyncValue.loading();
      expect(state.isLoading, isTrue);
      expect(state.hasError, isFalse);

      // Successful recovery
      state = const AsyncValue.data(42);
      expect(state.hasValue, isTrue);
      expect(state.value, equals(42));
    });

    test('3. AsyncValue empty list handling is distinguishable from error', () {
      const emptyState = AsyncValue.data(<String>[]);
      expect(emptyState.hasValue, isTrue);
      expect(emptyState.value!.isEmpty, isTrue);
      expect(emptyState.hasError, isFalse);

      final errorState = AsyncValue<List<String>>.error(
        Exception('Permission denied'),
        StackTrace.current,
      );
      expect(errorState.hasError, isTrue);
      expect(errorState.hasValue, isFalse);
    });

    test('4. StateNotifier lifecycle handles mutation and failure immutability', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final stateProvider = StateProvider<AsyncValue<String>>(
        (ref) => const AsyncValue.loading(),
      );

      expect(container.read(stateProvider), isA<AsyncLoading>());

      container.read(stateProvider.notifier).state =
          const AsyncValue.data('Operational');
      expect(container.read(stateProvider).value, equals('Operational'));

      container.read(stateProvider.notifier).state =
          AsyncValue.error('Network failure', StackTrace.empty);
      expect(container.read(stateProvider).hasError, isTrue);
    });
  });
}

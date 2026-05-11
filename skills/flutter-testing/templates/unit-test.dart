// Unit test template — Replace [FeatureName] with actual domain name
// Pattern: Given-When-Then, pure Dart, no widget tree, deterministic

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

// ===========================================================================
// FAKES AND MOCKS
// ===========================================================================

// Prefer Fake (stateful) over Mock (verification-based) for repositories
class FakeFeatureNameRepository extends Fake implements FeatureNameRepository {
  List<FeatureNameModel> items = [];
  bool shouldThrow = false;
  Exception? exceptionToThrow;

  @override
  Future<List<FeatureNameModel>> getAll() async {
    if (shouldThrow) throw exceptionToThrow ?? const FeatureNameNetworkException();
    return List.of(items);
  }

  @override
  Future<void> delete(String id) async {
    if (shouldThrow) throw exceptionToThrow ?? const FeatureNameNetworkException();
    items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> create(CreateFeatureNameRequest request) async {
    if (shouldThrow) throw exceptionToThrow ?? const FeatureNameNetworkException();
    items.add(FeatureNameModel(id: 'generated-${items.length}', title: request.title));
  }
}

// Use Mock for dependencies you want to verify calls on
class MockAnalyticsService extends Mock implements AnalyticsService {}

// ===========================================================================
// TEST SETUP HELPERS
// ===========================================================================

ProviderContainer buildContainer({
  FakeFeatureNameRepository? repo,
  List<Override> overrides = const [],
}) {
  return ProviderContainer(
    overrides: [
      featureNameRepositoryProvider.overrideWithValue(
        repo ?? FakeFeatureNameRepository(),
      ),
      ...overrides,
    ],
  );
}

// ===========================================================================
// UNIT TESTS
// ===========================================================================

void main() {
  late FakeFeatureNameRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = FakeFeatureNameRepository()
      ..items = [
        const FeatureNameModel(id: '1', title: 'First item'),
        const FeatureNameModel(id: '2', title: 'Second item'),
      ];
    container = buildContainer(repo: fakeRepo);
  });

  tearDown(() => container.dispose());

  // ---------------------------------------------------------------------------
  group('FeatureNameNotifier.build', () {
    test('loads items from repository on build', () async {
      final items = await container.read(featureNameNotifierProvider.future);

      expect(items, hasLength(2));
      expect(items.first.title, 'First item');
    });

    test('returns empty list when repository has no items', () async {
      fakeRepo.items = [];

      final items = await container.read(featureNameNotifierProvider.future);

      expect(items, isEmpty);
    });

    test('emits AsyncError when repository throws', () async {
      fakeRepo.shouldThrow = true;

      // Wait for build to complete
      await container.read(featureNameNotifierProvider.future).catchError((_) => []);
      final state = container.read(featureNameNotifierProvider);

      expect(state, isA<AsyncError<List<FeatureNameModel>>>());
    });
  });

  // ---------------------------------------------------------------------------
  group('FeatureNameNotifier.delete', () {
    test('removes item optimistically from state', () async {
      // Wait for initial load
      await container.read(featureNameNotifierProvider.future);

      await container.read(featureNameNotifierProvider.notifier).delete('1');

      final state = container.read(featureNameNotifierProvider);
      final items = state.requireValue;
      expect(items.where((i) => i.id == '1'), isEmpty);
    });

    test('rolls back state when delete fails', () async {
      await container.read(featureNameNotifierProvider.future);
      final previousItems = container.read(featureNameNotifierProvider).requireValue;

      fakeRepo.shouldThrow = true;
      await container.read(featureNameNotifierProvider.notifier).delete('1');

      final currentItems = container.read(featureNameNotifierProvider).requireValue;
      expect(currentItems, equals(previousItems)); // Rolled back
    });
  });

  // ---------------------------------------------------------------------------
  group('FeatureNameNotifier.refresh', () {
    test('reloads items from repository', () async {
      await container.read(featureNameNotifierProvider.future);

      // Simulate new data arriving
      fakeRepo.items.add(const FeatureNameModel(id: '3', title: 'New item'));
      await container.read(featureNameNotifierProvider.notifier).refresh();

      final items = container.read(featureNameNotifierProvider).requireValue;
      expect(items, hasLength(3));
    });
  });

  // ---------------------------------------------------------------------------
  // DOMAIN LOGIC TESTS (pure unit tests — no Riverpod needed)
  group('FeatureNameModel', () {
    test('equality is value-based', () {
      const a = FeatureNameModel(id: '1', title: 'Test');
      const b = FeatureNameModel(id: '1', title: 'Test');
      expect(a, equals(b));
    });

    test('copyWith produces new instance with updated fields', () {
      const model = FeatureNameModel(id: '1', title: 'Original');
      final updated = model.copyWith(title: 'Updated');
      expect(updated.title, 'Updated');
      expect(updated.id, '1'); // Unchanged field preserved
    });
  });
}

// Async Notifier template — replace [FeatureName] with actual name
// Handles: loading, error, data, optimistic updates, refresh

import 'package:riverpod_annotation/riverpod_annotation.dart';

part '[feature_name]_notifier.g.dart';

// ===========================================================================
// STATE MODEL (use freezed for complex state, simple class for primitives)
// ===========================================================================

// Option A: Simple state (primitive/value object)
// Use directly: @riverpod class MyNotifier extends _$MyNotifier

// Option B: Complex state (multiple fields) — use freezed
@freezed
class FeatureNameState with _$FeatureNameState {
  const factory FeatureNameState({
    required List<FeatureNameModel> items,
    @Default(false) bool isSubmitting,
    String? errorMessage,
  }) = _FeatureNameState;
}

// ===========================================================================
// ASYNC NOTIFIER — server state with loading/error/data
// ===========================================================================

@riverpod
class FeatureNameNotifier extends _$FeatureNameNotifier {
  // Build: called on first watch — returns initial async state
  @override
  Future<List<FeatureNameModel>> build() async {
    return _repository.getAll();
  }

  FeatureNameRepository get _repository =>
      ref.read(featureNameRepositoryProvider);

  // Refresh: reload from server
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.getAll);
  }

  // Optimistic delete: update UI immediately, rollback on failure
  Future<void> delete(String id) async {
    final previous = state;

    state = AsyncData(
      state.requireValue.where((item) => item.id != id).toList(),
    );

    try {
      await _repository.delete(id);
    } catch (e, st) {
      state = previous; // Rollback
      // Optional: surface error via separate error provider
    }
  }

  // Create: add and refresh
  Future<void> create(CreateFeatureNameRequest request) async {
    try {
      await _repository.create(request);
      await refresh();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

// ===========================================================================
// USAGE IN WIDGET
// ===========================================================================

class FeatureNameScreen extends ConsumerWidget {
  const FeatureNameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(featureNameNotifierProvider);

    return Scaffold(
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.read(featureNameNotifierProvider.notifier).refresh(),
        ),
        data: (items) => _FeatureNameList(items: items),
      ),
    );
  }
}

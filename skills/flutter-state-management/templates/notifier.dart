// Notifier template — synchronous / mixed state
// Replace [FeatureName] with actual domain name
// Run: dart run build_runner build --delete-conflicting-outputs

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '[feature_name]_notifier.freezed.dart';
part '[feature_name]_notifier.g.dart';

// ===========================================================================
// STATE (sealed class for complex multi-state, or simple type for primitives)
// ===========================================================================

@freezed
sealed class FeatureNameState with _$FeatureNameState {
  const factory FeatureNameState.initial() = FeatureNameInitial;
  const factory FeatureNameState.loading() = FeatureNameLoading;
  const factory FeatureNameState.success(List<FeatureNameModel> items) = FeatureNameSuccess;
  const factory FeatureNameState.failure(String message) = FeatureNameFailure;
}

// ===========================================================================
// NOTIFIER
// ===========================================================================

@riverpod
class FeatureNameNotifier extends _$FeatureNameNotifier {
  @override
  FeatureNameState build() => const FeatureNameState.initial();

  Future<void> load() async {
    state = const FeatureNameState.loading();
    try {
      final items = await ref.read(featureNameRepositoryProvider).getAll();
      state = FeatureNameState.success(items);
    } on FeatureNameException catch (e) {
      state = FeatureNameState.failure(e.message ?? 'Unknown error');
    }
  }

  Future<void> create(CreateFeatureNameRequest request) async {
    if (state is! FeatureNameSuccess) return;
    try {
      await ref.read(featureNameRepositoryProvider).create(request);
      await load(); // Reload after creation
    } on FeatureNameException catch (e) {
      state = FeatureNameState.failure(e.message ?? 'Failed to create');
    }
  }
}

// ===========================================================================
// USAGE IN WIDGET (pattern-match on sealed state)
// ===========================================================================

class FeatureNameWidget extends ConsumerWidget {
  const FeatureNameWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(featureNameNotifierProvider);

    return switch (state) {
      FeatureNameInitial() => _buildInitial(context, ref),
      FeatureNameLoading() => const CircularProgressIndicator(),
      FeatureNameSuccess(:final items) => _buildList(items),
      FeatureNameFailure(:final message) => _buildError(message, ref),
    };
  }

  Widget _buildInitial(BuildContext context, WidgetRef ref) {
    // Trigger load on first render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(featureNameNotifierProvider.notifier).load();
    });
    return const SizedBox.shrink();
  }

  Widget _buildList(List<FeatureNameModel> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) => ListTile(title: Text(items[i].title)),
    );
  }

  Widget _buildError(String message, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(message),
        ElevatedButton(
          onPressed: () => ref.read(featureNameNotifierProvider.notifier).load(),
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

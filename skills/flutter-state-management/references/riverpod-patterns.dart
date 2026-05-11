// Riverpod 3 patterns reference — copy-paste ready implementations

// ===========================================================================
// 1. BASIC NOTIFIER (synchronous state)
// ===========================================================================

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'counter_notifier.g.dart'; // Run build_runner

@riverpod
class CounterNotifier extends _$CounterNotifier {
  @override
  int build() => 0; // Initial state

  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}

// Usage:
// final count = ref.watch(counterNotifierProvider);
// ref.read(counterNotifierProvider.notifier).increment();

// ===========================================================================
// 2. ASYNC NOTIFIER (server state)
// ===========================================================================

@riverpod
class ProductListNotifier extends _$ProductListNotifier {
  @override
  Future<List<Product>> build() async {
    // Called on first watch — returns initial data
    return ref.watch(productRepositoryProvider).watchAll().first;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(productRepositoryProvider).watchAll().first,
    );
  }

  Future<void> deleteProduct(String id) async {
    final previous = state; // Save for rollback
    // Optimistic update
    state = AsyncData(
      state.requireValue.where((p) => p.id != id).toList(),
    );
    try {
      await ref.read(productRepositoryProvider).delete(id);
    } catch (e, st) {
      state = previous; // Rollback
      state = AsyncError(e, st);
    }
  }
}

// ===========================================================================
// 3. STREAM NOTIFIER (continuous real-time state)
// ===========================================================================

@riverpod
class CartNotifier extends _$CartNotifier {
  @override
  Stream<Cart> build() {
    // Automatically handles stream lifecycle — cancel on dispose
    return ref.watch(cartRepositoryProvider).watchCart(
      userId: ref.watch(currentUserProvider).id,
    );
  }
}

// ===========================================================================
// 4. FAMILY PROVIDER (parameterized)
// ===========================================================================

@riverpod
Future<Product> productDetail(Ref ref, String productId) async {
  return ref.watch(productRepositoryProvider).getById(productId);
}

// Usage:
// ref.watch(productDetailProvider('product-123'))

// ===========================================================================
// 5. SELECT — GRANULAR SUBSCRIPTION (performance critical)
// ===========================================================================

// In widget — only rebuilds when name changes, not entire user object
Widget build(BuildContext context, WidgetRef ref) {
  final userName = ref.watch(
    currentUserProvider.select((user) => user.displayName),
  );
  return Text(userName);
}

// ===========================================================================
// 6. REF.LISTEN — SIDE EFFECTS (navigation, dialogs, snackbars)
// ===========================================================================

class LoginScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  void initState() {
    super.initState();
    // React to auth state changes without rebuilding
    ref.listenManual(
      authStateProvider,
      (previous, next) {
        if (next is AuthAuthenticated) {
          context.go('/home');
        }
        if (next is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.message)),
          );
        }
      },
    );
  }
}

// ===========================================================================
// 7. PROVIDER CONTAINER (for unit tests — no widget tree needed)
// ===========================================================================

void main() {
  group('ProductListNotifier', () {
    late ProviderContainer container;
    late FakeProductRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeProductRepository();
      container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() => container.dispose()); // Always dispose!

    test('returns products on build', () async {
      final products = await container.read(
        productListNotifierProvider.future,
      );
      expect(products, isNotEmpty);
    });

    test('refreshes successfully', () async {
      await container.read(productListNotifierProvider.notifier).refresh();
      expect(
        container.read(productListNotifierProvider),
        isA<AsyncData<List<Product>>>(),
      );
    });
  });
}

// ===========================================================================
// 8. KEEPING ALIVE (prevent disposal of expensive providers)
// ===========================================================================

@riverpod
class ExpensiveDataNotifier extends _$ExpensiveDataNotifier {
  @override
  Future<ExpensiveData> build() async {
    // Keep alive while any listener exists
    ref.keepAlive();
    return await loadExpensiveData();
  }
}

// ===========================================================================
// 9. AUTO-DISPOSE FAMILY WITH CANCELLATION
// ===========================================================================

@riverpod
Future<SearchResult> searchProducts(Ref ref, String query) async {
  // Cancel in-flight request if query changes (re-executed)
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  return ref.watch(productRepositoryProvider).search(
    query,
    cancelToken: cancelToken,
  );
}

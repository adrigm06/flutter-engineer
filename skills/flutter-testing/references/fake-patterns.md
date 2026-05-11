# Fake Repository Patterns

## Why Fakes over Mocks

| | Fake | Mock (mocktail) |
|---|---|---|
| State | ✅ Stateful — accumulates data | ❌ Stateless by default |
| Verification | Not primary goal | ✅ Verify method calls |
| Test isolation | ✅ Excellent | ✅ Good |
| Boilerplate | Medium | Low (with mocktail) |
| Recommended for | Repositories, stateful services | Simple single-call verification |

**Rule**: Use `Fake*` implementations for repositories and stateful services.
Use `Mock` (mocktail) for external side effects (analytics, logging) where you want to verify calls.

---

## Base Fake Repository Pattern

```dart
// test/fakes/fake_product_repository.dart
class FakeProductRepository extends Fake implements ProductRepository {
  // State (what the fake stores in memory)
  final List<Product> _products;
  
  // Behavior controls (set in tests)
  bool shouldThrow = false;
  Exception? exceptionToThrow;
  bool shouldHang = false;            // Simulates infinite loading
  Duration responseDelay = Duration.zero; // Simulates latency

  FakeProductRepository({List<Product>? initialProducts})
      : _products = List.of(initialProducts ?? []);

  void addProduct(Product product) => _products.add(product);
  void clearAll() => _products.clear();

  Future<T> _execute<T>(T Function() fn) async {
    if (shouldHang) return Completer<T>().future; // Never completes
    await Future.delayed(responseDelay);
    if (shouldThrow) throw exceptionToThrow ?? const NetworkException();
    return fn();
  }

  @override
  Future<List<Product>> getAll() => _execute(() => List.of(_products));

  @override
  Future<Product> getById(String id) => _execute(() {
    final product = _products.where((p) => p.id == id).firstOrNull;
    if (product == null) throw NotFoundException(id: id);
    return product;
  });

  @override
  Future<void> create(CreateProductRequest request) => _execute(() {
    _products.add(Product(
      id: 'fake-${_products.length + 1}',
      title: request.title,
      price: request.price,
    ));
  });

  @override
  Future<void> update(Product product) => _execute(() {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index == -1) throw NotFoundException(id: product.id);
    _products[index] = product;
  });

  @override
  Future<void> delete(String id) => _execute(() {
    _products.removeWhere((p) => p.id == id);
  });

  // Reactive stream (local-only, no remote sync)
  @override
  Stream<List<Product>> watchAll() async* {
    yield List.of(_products);
    // In tests: yield new values by calling addProduct() + re-triggering
  }
}
```

---

## Test Fixtures (Shared Data)

```dart
// test/fixtures/product_fixtures.dart
abstract final class ProductFixtures {
  static const Product apple = Product(
    id: 'product-1',
    title: 'Apple',
    price: 1.99,
    category: 'fruit',
  );

  static const Product banana = Product(
    id: 'product-2',
    title: 'Banana',
    price: 0.99,
    category: 'fruit',
  );

  static List<Product> get defaultList => [apple, banana];

  static FakeProductRepository repoWithDefaults() =>
      FakeProductRepository(initialProducts: defaultList);

  static FakeProductRepository emptyRepo() =>
      FakeProductRepository(initialProducts: []);

  static FakeProductRepository failingRepo() =>
      FakeProductRepository()..shouldThrow = true;
}
```

---

## Mock for side-effect verification

```dart
// Use mocktail for verifying analytics calls, not for stateful repos
class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  test('tracks product viewed event', () async {
    final analytics = MockAnalyticsService();
    final container = ProviderContainer(
      overrides: [analyticsServiceProvider.overrideWithValue(analytics)],
    );

    await container.read(productDetailProvider('1').future);

    verify(() => analytics.trackProductViewed(productId: '1')).called(1);
  });
}
```

---

## Clock injection (deterministic time in tests)

```dart
// Production code — inject clock, never call DateTime.now() directly
class OrderService {
  const OrderService({required Clock clock});
  final Clock clock;

  Order createOrder(Cart cart) => Order(
    id: generateId(),
    items: cart.items,
    createdAt: clock.now(), // ✅ Injected — testable
  );
}

// Test
test('order has correct timestamp', () {
  final fixedTime = DateTime(2025, 1, 15, 10, 30);
  final service = OrderService(clock: Clock.fixed(fixedTime));

  final order = service.createOrder(testCart);

  expect(order.createdAt, equals(fixedTime));
});
```

---

## FakeAsync for timer/animation tests

```dart
import 'package:fake_async/fake_async.dart';

test('retry happens after 1 second backoff', () {
  fakeAsync((async) {
    final service = RetryService(clock: async.getClock(DateTime.now()));
    int callCount = 0;

    service.withRetry(() {
      callCount++;
      if (callCount < 3) throw const NetworkException();
    });

    // No retries yet
    expect(callCount, 1);

    // Advance time by 1s — triggers first retry
    async.elapse(const Duration(seconds: 1));
    expect(callCount, 2);

    // Advance 2s more — triggers second retry
    async.elapse(const Duration(seconds: 2));
    expect(callCount, 3);
  });
});
```

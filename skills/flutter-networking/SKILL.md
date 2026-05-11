---
name: flutter-networking
description: >
  Lead authority for Flutter networking. Use when designing HTTP client architecture,
  implementing Dio interceptors, retry/backoff logic, auth token refresh, caching,
  optimistic updates, or offline sync networking layer.
---

# Flutter Networking Skill

## Purpose

Design and implement a production-grade networking layer for Flutter apps — resilient,
observable, secure, and testable. Covers Dio configuration, interceptors, retry, caching,
auth refresh, cancellation, and offline-aware request handling.

## Scope and authority

Lead authority for:

- HTTP client architecture (Dio configuration, base options)
- interceptor chain design (auth, retry, logging, connectivity)
- authentication token refresh (transparent, non-blocking)
- caching strategy (ETag, stale-while-revalidate, cache busting)
- optimistic updates and rollback
- request cancellation and timeout policies
- offline-aware request queuing

Defers to:

- `flutter-security` for SSL pinning, transport hardening
- `flutter-storage` for local cache persistence
- `flutter-offline-first` for full offline sync architecture

---

## When to use

- Setting up HTTP client for new project
- Implementing auth token refresh in interceptor
- Designing retry and backoff logic
- Adding response caching (ETag, TTL)
- Handling network errors with user-friendly fallbacks
- Implementing optimistic mutations with rollback
- Cancelling requests on screen disposal

---

## Required stack

```yaml
dependencies:
  dio: ^5.x
  dio_cache_interceptor: ^3.x

dev_dependencies:
  mockito: # or mocktail for testing interceptors
```

---

## Dio client architecture

### Base client setup

```dart
// core/network/api_client.dart
class ApiClient {
  ApiClient({
    required String baseUrl,
    required AuthInterceptor authInterceptor,
    required RetryInterceptor retryInterceptor,
    required LoggingInterceptor loggingInterceptor,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    )
      ..interceptors.addAll([
        authInterceptor,         // 1st: inject auth token
        retryInterceptor,        // 2nd: retry on failure
        loggingInterceptor,      // 3rd: log (debug only)
      ]);
  }

  late final Dio _dio;
  Dio get dio => _dio;
}
```

---

## Required interceptors

### 1. Auth interceptor (transparent token refresh)

```dart
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.tokenRepository,
    required this.authNotifier,
  });

  final TokenRepository tokenRepository;
  final AuthNotifier authNotifier;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenRepository.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        // Attempt silent token refresh
        final newToken = await tokenRepository.refreshAccessToken();
        final retryRequest = err.requestOptions
          ..headers['Authorization'] = 'Bearer $newToken';
        final response = await Dio().fetch(retryRequest);
        handler.resolve(response);
        return;
      } catch (_) {
        // Refresh failed — force logout
        authNotifier.signOut();
      }
    }
    handler.next(err);
  }
}
```

### 2. Retry interceptor (exponential backoff)

```dart
class RetryInterceptor extends Interceptor {
  RetryInterceptor({this.maxRetries = 3});

  final int maxRetries;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_shouldRetry(err)) {
      var retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;
      if (retryCount < maxRetries) {
        retryCount++;
        err.requestOptions.extra['retryCount'] = retryCount;
        // Exponential backoff: 1s, 2s, 4s
        await Future.delayed(Duration(seconds: 1 << (retryCount - 1)));
        try {
          final response = await Dio().fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (e) {
          // Fall through to next retry or give up
        }
      }
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.response?.statusCode == 503;
  }
}
```

### 3. Logging interceptor (debug only)

```dart
class LoggingInterceptor extends Interceptor {
  // Only active in debug mode — never in release
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      debugPrint('→ ${options.method} ${options.uri}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    assert(() {
      debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
      return true;
    }());
    handler.next(response);
  }
}
// ❌ Never log request bodies — may contain sensitive data
// ❌ Never log Authorization headers
```

---

## Caching strategy

### ETag-based caching with dio_cache_interceptor

```dart
final cacheStore = HiveCacheStore('cache_path');

final cacheInterceptor = DioCacheInterceptor(
  options: CacheOptions(
    store: cacheStore,
    policy: CachePolicy.request, // Use cache, validate with ETag
    hitCacheOnErrorExcept: [401, 403],
    maxStale: const Duration(days: 7),
  ),
);
```

### Stale-while-revalidate pattern

```dart
// In repository:
Stream<List<Product>> watchProducts() async* {
  // 1. Yield cached data immediately
  final cached = await localDataSource.getProducts();
  if (cached.isNotEmpty) yield cached;

  // 2. Fetch fresh data
  final fresh = await remoteDataSource.fetchProducts();

  // 3. Update local cache
  await localDataSource.replaceProducts(fresh);

  // 4. Yield fresh data
  yield fresh;
}
```

---

## Request cancellation

```dart
// In repository or use case:
class ProductRepository {
  final _cancelTokens = <String, CancelToken>{};

  Future<List<Product>> searchProducts(String query) async {
    // Cancel any previous search request
    _cancelTokens['search']?.cancel('New search initiated');
    final cancelToken = CancelToken();
    _cancelTokens['search'] = cancelToken;

    try {
      return await _remoteSource.searchProducts(
        query,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return []; // Expected
      rethrow;
    }
  }
}
```

---

## Error handling strategy

```dart
// core/network/network_exception.dart
sealed class NetworkException {
  const NetworkException();
}

class NoConnectionException extends NetworkException {}
class UnauthorizedException extends NetworkException {}
class NotFoundException extends NetworkException {}
class ServerException extends NetworkException {
  const ServerException({required this.message});
  final String message;
}
class TimeoutException extends NetworkException {}

// Repository error mapping
NetworkException _mapDioException(DioException e) => switch (e.type) {
  DioExceptionType.connectionError => const NoConnectionException(),
  DioExceptionType.connectionTimeout => const TimeoutException(),
  _ => switch (e.response?.statusCode) {
    401 => const UnauthorizedException(),
    404 => const NotFoundException(),
    _ => ServerException(message: e.message ?? 'Unknown error'),
  },
};
```

---

## Anti-pattern detection

- Dio instance created inside widget or provider (use singleton)
- Auth header injected manually in each request (use interceptor)
- No retry logic for transient failures
- No timeout configuration (default is no timeout — dangerous)
- Authorization header logged (security violation)
- `dynamic` return type from API methods
- Exception swallowing without logging
- CancelToken not used for search/type-ahead requests
- Response caching without ETag validation (stale data risk)
- Network calls directly in widget `build()` method

---

## Uncertainty protocol

- `High` (≥ 0.80): API contract clear, auth model known
- `Medium` (0.60–0.79): API contract partial or auth flow unclear
- `Low` (< 0.60): no API specification available

---

## Cross-skill handoff payload

Use the standard payload from `../../AGENTS.md`.
Set `requesting_skill` to `flutter-networking`.

---

## Output contract

Follow global section order from `../../AGENTS.md`. Also include:

- `Dio client configuration`
- `Interceptor chain design`
- `Error handling strategy`
- `Caching approach`
- `Test strategy for network layer`

---

## Related resources

- `references/dio-patterns.md`
- `references/caching-strategies.md`
- `references/auth-refresh-patterns.md`
- `templates/api-client.dart`
- `templates/auth-interceptor.dart`
- `templates/repository-network.dart`

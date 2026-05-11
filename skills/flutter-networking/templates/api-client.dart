// Dio ApiClient template — production-ready with all interceptors wired
// Replace base URL and interceptor configs for your app

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_client.g.dart';

// ===========================================================================
// DIO PROVIDER
// ===========================================================================

@riverpod
Dio dio(Ref ref) {
  final authInterceptor = ref.watch(authInterceptorProvider);
  final retryInterceptor = ref.watch(retryInterceptorProvider);

  return Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-App-Version': PackageInfo.version,
      },
    ),
  )
    ..interceptors.addAll([
      authInterceptor,                    // 1. Inject auth token
      retryInterceptor,                   // 2. Retry on transient failure
      if (kDebugMode) LoggingInterceptor(), // 3. Log (debug only)
    ]);
}

// ===========================================================================
// AUTH INTERCEPTOR
// ===========================================================================

@riverpod
AuthInterceptor authInterceptor(Ref ref) {
  return AuthInterceptor(
    tokenStorage: ref.watch(secureTokenStorageProvider),
    onRefreshFailed: () => ref.read(authStateProvider.notifier).signOut(),
  );
}

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.tokenStorage,
    required this.onRefreshFailed,
  });

  final SecureTokenStorage tokenStorage;
  final VoidCallback onRefreshFailed;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenStorage.getAccessToken();
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
        final newToken = await tokenStorage.refreshAccessToken();
        final retried = err.requestOptions
          ..headers['Authorization'] = 'Bearer $newToken';
        final response = await Dio().fetch(retried);
        handler.resolve(response);
        return;
      } catch (_) {
        onRefreshFailed();
      }
    }
    handler.next(err);
  }
}

// ===========================================================================
// RETRY INTERCEPTOR
// ===========================================================================

@riverpod
RetryInterceptor retryInterceptor(Ref ref) => const RetryInterceptor();

class RetryInterceptor extends Interceptor {
  const RetryInterceptor({this.maxRetries = 3});
  final int maxRetries;

  static const _retryCountKey = '_retry_count';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isRetryable(err)) {
      handler.next(err);
      return;
    }

    final retryCount = (err.requestOptions.extra[_retryCountKey] as int?) ?? 0;

    if (retryCount >= maxRetries) {
      handler.next(err);
      return;
    }

    // Exponential backoff: 1s, 2s, 4s
    await Future.delayed(Duration(seconds: 1 << retryCount));

    err.requestOptions.extra[_retryCountKey] = retryCount + 1;

    try {
      final response = await Dio().fetch(err.requestOptions);
      handler.resolve(response);
    } catch (e) {
      handler.next(err); // Give up after maxRetries
    }
  }

  bool _isRetryable(DioException err) =>
      err.type == DioExceptionType.connectionTimeout ||
      err.type == DioExceptionType.receiveTimeout ||
      err.type == DioExceptionType.connectionError ||
      err.response?.statusCode == 503 ||
      err.response?.statusCode == 504;
}

// ===========================================================================
// LOGGING INTERCEPTOR (debug only)
// ===========================================================================

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      debugPrint('→ ${options.method} ${options.uri}');
      // ❌ NEVER log: options.headers['Authorization']
      // ❌ NEVER log: options.data (may contain passwords)
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

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      debugPrint('✗ ${err.response?.statusCode} ${err.requestOptions.uri}: ${err.message}');
      return true;
    }());
    handler.next(err);
  }
}

// ===========================================================================
// NETWORK EXCEPTION MAPPER
// ===========================================================================

sealed class NetworkException implements Exception {
  const NetworkException();
}

class NoConnectionException extends NetworkException {
  const NoConnectionException();
}

class UnauthorizedException extends NetworkException {
  const UnauthorizedException();
}

class NotFoundException extends NetworkException {
  const NotFoundException();
}

class ServerException extends NetworkException {
  const ServerException({required this.message, this.statusCode});
  final String message;
  final int? statusCode;
}

class TimeoutException extends NetworkException {
  const TimeoutException();
}

NetworkException mapDioException(DioException e) => switch (e.type) {
  DioExceptionType.connectionError => const NoConnectionException(),
  DioExceptionType.connectionTimeout => const TimeoutException(),
  DioExceptionType.receiveTimeout => const TimeoutException(),
  _ => switch (e.response?.statusCode) {
    401 => const UnauthorizedException(),
    404 => const NotFoundException(),
    final int code => ServerException(
        message: e.message ?? 'Server error',
        statusCode: code,
      ),
    null => ServerException(message: e.message ?? 'Unknown error'),
  },
};

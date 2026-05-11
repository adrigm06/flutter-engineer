---
name: flutter-observability
description: >
  Lead authority for Flutter observability. Use when implementing crash reporting,
  structured logging, performance monitoring, distributed tracing, analytics governance,
  feature flags, or privacy-safe telemetry.
---

# Flutter Observability Skill

## Purpose

Instrument Flutter apps with production-grade observability — crashes, logs, performance traces,
analytics, feature flags — while maintaining user privacy and regulatory compliance.

## Scope and authority

Lead authority for:

- crash reporting (Firebase Crashlytics, Sentry)
- structured logging architecture
- performance monitoring (Firebase Performance, custom traces)
- distributed tracing (OpenTelemetry Dart)
- analytics governance (Firebase Analytics, privacy-safe)
- feature flags (Firebase Remote Config)
- runtime diagnostics and health signals

Defers to:

- `flutter-security` for PII in logs (override authority)
- `flutter-build-release` for release monitoring gates

---

## Observability stack (recommended defaults)

| Signal | Tool | Alternative |
|---|---|---|
| Crash reporting | Firebase Crashlytics | Sentry |
| Performance traces | Firebase Performance | Custom OTel |
| Structured logging | `logging` package + sink | Sentry Breadcrumbs |
| Analytics | Firebase Analytics | Amplitude, Mixpanel |
| Feature flags | Firebase Remote Config | LaunchDarkly |
| Distributed tracing | OpenTelemetry Dart | - |
| Health dashboards | Firebase Console | Grafana |

---

## Crash reporting setup (Crashlytics)

### Flutter error handling

```dart
// lib/bootstrap/error_handler.dart
Future<void> setupCrashReporting() async {
  // 1. Capture Flutter framework errors
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  // 2. Capture async errors outside Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // 3. Capture Isolate errors
  Isolate.current.addErrorListener(RawReceivePort((List<dynamic> pair) {
    final List<dynamic> errorAndStacktrace = pair;
    FirebaseCrashlytics.instance.recordError(
      errorAndStacktrace.first,
      errorAndStacktrace.last as StackTrace,
    );
  }).sendPort);
}

// In main():
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupCrashReporting();

  // Disable in debug mode (avoid noise in development)
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);

  runApp(const ProviderScope(child: MyApp()));
}
```

### User context (non-PII)

```dart
// Set user ID for crash correlation (never name/email)
await FirebaseCrashlytics.instance.setUserIdentifier(
  user.anonymizedId, // Hashed, never raw user ID if PII
);

// Custom keys for crash context
await FirebaseCrashlytics.instance.setCustomKey('app_flavor', AppConfig.environment.name);
await FirebaseCrashlytics.instance.setCustomKey('feature_flags', activeFlags.join(','));
```

---

## Structured logging

```dart
// core/logging/app_logger.dart
import 'package:logging/logging.dart';

class AppLogger {
  AppLogger._();

  static void initialize({required bool isDebug}) {
    Logger.root.level = isDebug ? Level.ALL : Level.WARNING;
    Logger.root.onRecord.listen(_handleLogRecord);
  }

  static void _handleLogRecord(LogRecord record) {
    // Debug: print to console
    if (kDebugMode) {
      debugPrint('${record.level.name}: ${record.loggerName} — ${record.message}');
    }

    // Non-debug: send to Crashlytics breadcrumbs
    if (!kDebugMode && record.level >= Level.WARNING) {
      FirebaseCrashlytics.instance.log(
        '[${record.level.name}] ${record.loggerName}: ${record.message}',
        // ❌ Never include record.error details if they may contain PII
      );
    }
  }
}

// Feature-specific loggers
final _log = Logger('AuthRepository');

class AuthRepository {
  Future<User> signIn(String email, String password) async {
    _log.info('Sign-in attempt'); // ✅ No email in log
    try {
      final user = await _remoteSource.signIn(email, password);
      _log.info('Sign-in successful'); // ✅ No user data in log
      return user;
    } catch (e, stack) {
      _log.severe('Sign-in failed', e, stack); // ✅ Error without PII
      rethrow;
    }
  }
}
```

---

## Performance monitoring

### Custom traces

```dart
// Wrap critical user journey operations
Future<List<Product>> loadProductCatalog() async {
  final trace = FirebasePerformance.instance.newTrace('load_product_catalog');
  await trace.start();

  try {
    final products = await _repository.getProducts();
    trace.putAttribute('count', products.length.toString());
    trace.putMetric('product_count', products.length);
    return products;
  } finally {
    await trace.stop();
  }
}
```

### Network request monitoring

Firebase Performance automatically monitors network requests when configured.
For custom Dio integration:

```dart
// In Dio interceptor:
class PerformanceInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.extra['trace_start'] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    final startMs = response.requestOptions.extra['trace_start'] as int?;
    if (startMs != null) {
      final duration = DateTime.now().millisecondsSinceEpoch - startMs;
      _recordApiCall(
        path: response.requestOptions.path,
        statusCode: response.statusCode ?? 0,
        durationMs: duration,
      );
    }
    handler.next(response);
  }
}
```

---

## Feature flags (Firebase Remote Config)

```dart
// core/config/remote_config_service.dart
@riverpod
RemoteConfigService remoteConfigService(Ref ref) {
  return RemoteConfigService(FirebaseRemoteConfig.instance);
}

class RemoteConfigService {
  RemoteConfigService(this._remoteConfig);
  final FirebaseRemoteConfig _remoteConfig;

  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: kDebugMode
          ? Duration.zero
          : const Duration(hours: 1),
    ));

    // Set defaults that ship with the app
    await _remoteConfig.setDefaults({
      'new_checkout_flow_enabled': false,
      'max_retry_count': 3,
      'home_hero_experiment': 'control',
    });

    await _remoteConfig.fetchAndActivate();
  }

  bool isFeatureEnabled(String flag) =>
      _remoteConfig.getBool(flag);

  String getStringConfig(String key) =>
      _remoteConfig.getString(key);
}

// Usage in feature:
@riverpod
bool isNewCheckoutEnabled(Ref ref) {
  return ref
      .watch(remoteConfigServiceProvider)
      .isFeatureEnabled('new_checkout_flow_enabled');
}
```

---

## Analytics governance

### Privacy-safe event tracking

```dart
// core/analytics/analytics_service.dart
class AnalyticsService {
  AnalyticsService(this._analytics);
  final FirebaseAnalytics _analytics;

  // ✅ No PII in events — use IDs or categories only
  Future<void> trackProductViewed({
    required String productId,
    required String category,
  }) async {
    await _analytics.logEvent(
      name: 'product_viewed',
      parameters: {
        'product_id': productId,         // ✅ ID (not name, not price)
        'category': category,             // ✅ Category (not user data)
      },
    );
  }

  // ❌ Never track:
  // user.email, user.name, device IMEI,
  // precise location without consent,
  // search queries that may contain PII
}
```

### Event naming conventions

```
screen_viewed          → { screen_name: 'home' }
button_tapped          → { button_id: 'login_cta', screen: 'onboarding' }
feature_used           → { feature: 'offline_mode' }
error_occurred         → { error_type: 'network_timeout', screen: 'checkout' }
purchase_completed     → { currency: 'USD', value: 9.99 } // No user card data!
```

---

## OpenTelemetry (distributed tracing)

```dart
// For microservice-connected apps requiring distributed tracing
import 'package:opentelemetry/api.dart';
import 'package:opentelemetry/sdk.dart';

void setupTracing() {
  final exporter = OtlpGrpcSpanExporter(
    host: 'otel-collector.example.com',
    port: 4317,
  );

  sdk.registerGlobalTracerProvider(
    TracerProviderBase(
      processors: [BatchSpanProcessor(exporter)],
    ),
  );
}

// Instrument a critical operation:
Future<Order> placeOrder(Cart cart) async {
  final tracer = globalTracerProvider.getTracer('checkout');
  final span = tracer.startSpan('place_order');

  try {
    final order = await _orderRepository.create(cart);
    span.setStatus(StatusCode.ok);
    return order;
  } catch (e, stack) {
    span.recordException(e, stackTrace: stack);
    span.setStatus(StatusCode.error, description: e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
```

---

## Privacy compliance checklist

```
□ No PII in crash reports (names, emails, passwords)
□ Analytics events reviewed for PII before shipping
□ Remote Config values not used to collect user data
□ Analytics consent gate implemented (GDPR/CCPA)
□ Data retention policies configured in Firebase Console
□ User opt-out path implemented and working
□ Privacy policy updated to reflect tracked events
```

---

## Anti-pattern detection

- PII in crash reports or log messages → Critical security violation
- `print()` statements in production code → logging violation
- No global Flutter error handler set up → crashes silently lost
- Analytics events without privacy review → compliance risk
- Crashlytics collection enabled in debug builds → dev noise pollution
- No performance traces on critical user journeys → blind to regressions
- Feature flags hardcoded (not using Remote Config) → no production control

---

## Cross-skill handoff payload

Use the standard payload from `../../AGENTS.md`.
Set `requesting_skill` to `flutter-observability`.

---

## Output contract

Follow global section order from `../../AGENTS.md`. Also include:

- `Observability stack recommendation`
- `Crash reporting setup`
- `Logging architecture`
- `Performance trace plan`
- `Analytics events schema`
- `Privacy compliance checklist`

---

## Related resources

- `references/crashlytics-setup.md`
- `references/analytics-governance.md`
- `references/feature-flags-guide.md`
- `references/otel-setup.md`
- `templates/app-logger.dart`
- `templates/analytics-service.dart`
- `templates/remote-config-service.dart`

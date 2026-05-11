# Flutter Engineering Project Rules

## Feature-First Structure (Mandatory)

Every feature MUST follow this directory structure. Never use global `screens/`, `widgets/`, `models/`, or `services/` directories.

```
lib/
  features/
    auth/
      presentation/
        screens/
        widgets/
        view_models/
      application/         # Use cases / interactors (only if needed)
      domain/
        models/
        repositories/      # Abstract interfaces
        exceptions/
      data/
        repositories/      # Concrete implementations
        data_sources/
          remote/
          local/
        dtos/
    home/
      presentation/
      domain/
      data/
  core/
    network/
    storage/
    routing/
    di/
    utils/
    extensions/
    theme/
    l10n/
  bootstrap/               # App initialization and DI setup
  main.dart
  main_dev.dart
  main_prod.dart
```

---

## Architecture Styles Decision Rules

| Context | Architecture | When to Apply |
|---|---|---|
| Enterprise, large team, regulated | Clean Architecture | Domain complexity, compliance, multiple teams |
| Startup, small team, CRUD-heavy | Vertical Slice / MVVM | Speed, simplicity, low domain complexity |
| Medium app, 3-8 engineers | Modular Monolith | Balanced scalability, clear boundaries |
| Monorepo, multiple apps | Package-First | Independent deployment, shared code |
| Mission-critical, disconnected use | Offline-First | Reliability over connectivity |
| High-frequency domain events | Event-Driven | Realtime, complex state machines |
| Complex write/read asymmetry | CQRS-Lite | Audit trails, complex queries |

The AI must EXPLAIN:
- Why the chosen architecture fits the context
- What the tradeoffs are
- What the migration path is if the team outgrows it
- At what point they should reconsider

---

## State Management Decision Matrix

### Default (use for all new projects)
```
Riverpod 3 + AsyncNotifier / Notifier
```

### Selection Guide

| Situation | Solution | Justification |
|---|---|---|
| Default — any app | Riverpod 3 | Type-safe, testable, compile-time DI |
| Enterprise event-driven | flutter_bloc | Explicit event modeling, great DevTools |
| Ultra high-frequency UI signals | Signals (signals_flutter) | Zero-rebuild granularity |
| Ephemeral UI-only state | flutter_hooks | Local, scoped, no boilerplate |
| Complex forms with validation | Formz | Typed form field states |
| Backend event streams | StreamNotifier (Riverpod) | First-class stream integration |
| Pagination | infinite_scroll_pagination + Riverpod | Cursor/offset pagination |

### Strictly Forbidden
- GetX (globally prohibited — no exceptions)
- Global mutable singletons masquerading as state
- setState() for shared app state (only for truly local ephemeral state)
- BLoC without events (use Notifier instead)

---

## Navigation Rules

### Mandatory
- Use `go_router` for all navigation (declarative, URL-based, deep-link ready)
- Support deep links from day one
- Auth guards via `redirect` in GoRouter
- Shell routes for persistent bottom navigation
- Nested navigation via nested GoRouter

### Forbidden
- `Navigator.pushNamed` (use `context.go()` / `context.push()`)
- Hardcoded route strings scattered across the codebase (use route constants class)
- Business logic inside navigation guards (delegate to use case)

---

## Networking Rules

### Stack
```
Dio + dio_cache_interceptor + pretty_dio_logger (dev only)
```

### Required Interceptors
1. Auth interceptor (token injection + refresh logic)
2. Retry interceptor (exponential backoff, max 3 retries)
3. Connectivity interceptor (fail-fast when offline)
4. Logging interceptor (debug only, never in release)

### Patterns Required
- Repository layer wraps all network calls (no Dio in UI)
- `CancelToken` for all long-lived requests
- ETag/If-None-Match for cacheable GETs
- Optimistic updates with rollback on failure

---

## Storage Decision Matrix

| Need | Solution |
|---|---|
| Simple KV preferences | shared_preferences |
| Sensitive data (tokens, keys) | flutter_secure_storage |
| Relational data (offline-first) | Drift (SQLite) |
| Document/object data | Isar (community) |
| High-performance KV | Hive CE |
| File storage | path_provider + dart:io |
| Encrypted database | Drift + sqlcipher |

### Hard Rules
- Never store tokens, passwords, or PII in SharedPreferences
- Always use flutter_secure_storage for authentication material
- Always encrypt sensitive databases

---

## Performance Budget Rules

### Frame Budget
- 60fps target: 16ms per frame (UI thread + raster thread combined)
- 120fps target: 8.3ms per frame
- Jank: any frame exceeding 2× frame budget

### Required Optimizations
- `const` constructors everywhere applicable
- `RepaintBoundary` around expensive subtrees that rebuild independently
- `ListView.builder` / `SliverList` for all lists (never `Column` with `map().toList()`)
- `select()` for granular Riverpod subscriptions
- `Isolate.run()` for any computation > 4ms on UI thread
- `LayoutBuilder` local to the widget that needs it (not global)
- `AutomaticKeepAliveClientMixin` only when genuinely needed

### Forbidden Patterns
- `MediaQuery.of(context)` in leaf widgets (causes unnecessary rebuilds)
- `IntrinsicHeight` / `IntrinsicWidth` in hot paths
- Unnecessary `Opacity` widget (use `ColorFiltered` or `FadeTransition`)
- Unnecessary `ClipRRect` (use `BorderRadius` on `decoration`)
- Shader warmup skipped for complex animations
- Long-running sync operations on UI isolate

---

## Security Rules

### Authentication Material
- Tokens: `flutter_secure_storage` only
- Biometric: `local_auth` with keychain/keystore backend
- Never log tokens (not even truncated in debug mode)

### Network Security
- Certificate pinning for financial/health apps: `dio` + custom `SecurityContext`
- HTTPS enforced; no HTTP in production (use `android:usesCleartextTraffic="false"`)
- Root/jailbreak detection for high-security apps: `root_jailbreak_sentry` or equivalent

### Build Security
- `--obfuscate --split-debug-info=<dir>` required in all release builds
- API keys via CI secret injection (never in source)
- Separate flavors for dev/staging/prod with no prod keys in dev builds

---

## Testing Pyramid Rules

### Required Coverage Targets
- Unit tests: ≥ 90% coverage on domain + application layers
- Widget tests: all screens + critical reusable widgets
- Golden tests: design system components (Alchemist)
- E2E: all critical user journeys (Patrol)

### Test Tools Stack
| Layer | Tool |
|---|---|
| Unit | flutter_test + mocktail |
| Widget | flutter_test + WidgetTester |
| Golden | alchemist |
| E2E | patrol |
| Coverage | lcov + genhtml |

### Rules
- Use `Fake*` implementations over mocks for repositories
- Use `mocktail` for mocks (not mockito)
- Deterministic clocks: always inject `Clock` — never `DateTime.now()` directly
- No network calls in unit or widget tests
- Golden tests must run on a fixed text scale factor

---

## Linting and Static Analysis Stack

```yaml
# Required in every project
- very_good_analysis OR leancode_lint
- dart_code_metrics (DCM)
- custom_lint (for project-specific rules)
```

### Required DCM Checks
- Max widget size (build method lines)
- Max cyclomatic complexity
- No dynamic
- Prefer const constructors
- Avoid print
- Detect unused code

---

## Accessibility Rules (Non-Negotiable)

- All interactive elements must have `Semantics` labels
- Minimum tap target: 48×48 logical pixels
- Color contrast: ≥ 4.5:1 for body text, ≥ 3:1 for large text
- No color-only information conveyance
- Text scaling: test at 200% — no overflow, no clipping
- Focus traversal must be logical and complete
- Reduced motion: respect `MediaQuery.disableAnimations`

---

## i18n Rules

- All user-facing strings in ARB files — no hardcoded strings in widgets
- Use Flutter's built-in `flutter_localizations` + `intl`
- Consider `slang` for type-safe translations in large projects
- RTL support: test all layouts in RTL mode
- Locale-aware formatting for dates, numbers, currencies

---

## CI/CD Required Pipeline Stages

```yaml
stages:
  - analyze           # dart analyze + DCM
  - lint              # very_good_analysis violations
  - format_check      # dart format --check
  - test_unit         # flutter test + coverage
  - test_golden       # alchemist golden tests
  - test_patrol       # e2e on emulator (optional on PR)
  - build_dev         # debug APK/IPA for review
  - build_release     # release with obfuscation
  - coverage_gate     # fail if coverage drops below threshold
  - size_check        # fail if binary size regresses > 5%
```

---

## Observability Standards

| Signal | Tool |
|---|---|
| Crashes | Firebase Crashlytics |
| Structured logs | `logging` package + remote sink |
| Analytics | Firebase Analytics (privacy-safe) |
| Performance traces | Firebase Performance |
| Distributed tracing | OpenTelemetry Dart |
| Feature flags | Firebase Remote Config |
| User sessions | (opt-in, GDPR-compliant) |

### Rules
- Never log PII (names, emails, tokens) even in debug
- Sanitize stack traces before sending to remote
- All analytics events must pass privacy review

---

## Monorepo / Melos Rules

```yaml
# melos.yaml required in all multi-package projects
workspace:
  packages:
    - packages/**
    - apps/**

scripts:
  analyze: melos exec -- dart analyze
  test: melos exec -- flutter test
  bootstrap: melos bootstrap
```

- Each feature can become a standalone package when ownership dictates
- Shared packages: `core_ui`, `core_network`, `core_storage`, `design_system`
- Feature packages: `feature_auth`, `feature_home`, etc.
- No direct package-to-package feature dependencies (route through app-level DI)

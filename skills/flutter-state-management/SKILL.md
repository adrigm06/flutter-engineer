---
name: flutter-state-management
description: >
  Lead authority for state management selection, implementation, and rebuild optimization.
  Use when choosing between Riverpod/Bloc/Signals, designing provider trees, debugging
  rebuild storms, or migrating from legacy state solutions.
---

# Flutter State Management Skill

## Purpose

Select, implement, and optimize Flutter state management with the right tool for the context,
enforcing minimal rebuilds, testability, and clean separation between UI and business logic.

## Scope and authority

This skill is the **lead authority** for:

- state management solution selection (Riverpod / Bloc / Signals / Hooks)
- provider/notifier architecture and scoping
- rebuild optimization and granular subscription design
- form state management (Formz)
- async state patterns (AsyncNotifier, StreamNotifier)
- migration from Provider / GetX / setState to modern solutions

This skill **defers** to:

- `flutter-architecture` for layer boundaries and dependency direction
- `flutter-performance` for measured frame-time regressions caused by rebuilds
- `flutter-security` for state containing sensitive data

---

## When to use

- Selecting state management solution for new project or feature
- Diagnosing rebuild storms, jank caused by over-broad subscriptions
- Designing provider/notifier tree for complex features
- Migrating from legacy state solutions (Provider, GetX, setState)
- Implementing form state with validation
- Designing async state patterns with loading/error/data

---

## Required inputs

- team familiarity with state solutions
- app complexity (CRUD vs event-heavy vs realtime)
- performance requirements (rebuild sensitivity)
- current state solution (if migrating)
- offline/optimistic update requirements

---

## Decision engine workflow

1. Classify state type (ephemeral / shared / server / form).
2. Classify app complexity and team context.
3. Apply selection matrix (see below).
4. Design provider/notifier tree with correct scoping.
5. Define rebuild optimization strategy.
6. Validate against architecture constraints.
7. Return implementation plan with concrete code patterns.

---

## State classification

| Type | Definition | Solution |
|---|---|---|
| Ephemeral | Single widget, not shared | `StatefulWidget` + `setState` or `flutter_hooks` |
| Shared UI | Across widget subtree | Riverpod `Notifier` or `flutter_hooks` |
| App state | Persisted across features | Riverpod `Notifier` + optional persistence |
| Server state | Remote data + cache + sync | Riverpod `AsyncNotifier` + repository |
| Form state | Multi-field validation | Formz + Riverpod |
| Stream state | Continuous backend events | Riverpod `StreamNotifier` |
| Event-driven | Complex state machines | `flutter_bloc` with sealed events |

---

## Selection branching tree

### Branch A: default choice

For all new Flutter projects (2026):

```
Riverpod 3 with Notifier / AsyncNotifier
```

- Type-safe providers
- Compile-time dependency graph
- No BuildContext dependency
- First-class async support
- Excellent testability (ProviderContainer in tests)

### Branch B: when to deviate from Riverpod

- **flutter_bloc**: when the team needs explicit event modeling, complex state machines,
  audit trail of all state transitions, or existing enterprise BLoC codebase.

- **Signals (signals_flutter)**: when UI performance requires zero-rebuild granularity
  for high-frequency updates (e.g., real-time price tickers, animations, maps).

- **flutter_hooks**: for ephemeral UI-local state (animation controllers, focus nodes,
  text controllers) — combine with Riverpod for app state.

- **Formz**: for typed multi-field form validation with explicit field states.

### Branch C: what to NEVER use

```
❌ GetX — globally prohibited
❌ Provider (only as migration step toward Riverpod)
❌ Global mutable singletons
❌ setState() for shared app state
❌ InheritedWidget manual implementation (use Riverpod)
```

---

## Riverpod 3 patterns (required standards)

### Provider scoping rules

```dart
// ✅ Feature-scoped providers — defined in feature provider files
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() => const AuthState.initial();
}

// ✅ Repository providers — singleton per app lifecycle
@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
  );
}

// ❌ Never define providers inside widget build() methods
// ❌ Never use ProviderScope.override without tests
```

### Granular subscription (mandatory for performance)

```dart
// ✅ Use select() to subscribe to specific fields only
final userName = ref.watch(userProvider.select((user) => user.name));

// ❌ Never watch entire provider when only one field needed
final user = ref.watch(userProvider); // rebuilds on ALL user changes
```

### AsyncNotifier pattern (server state)

```dart
@riverpod
class ProductList extends _$ProductList {
  @override
  Future<List<Product>> build() async {
    return ref.watch(productRepositoryProvider).getProducts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(productRepositoryProvider).getProducts(),
    );
  }
}
```

---

## Rebuild optimization rules

1. **Use `select()`** for any watch that needs only part of a larger state object.
2. **Use `Consumer` widgets** to isolate rebuild scope inside larger widget trees.
3. **Use `const` constructors** everywhere — const widgets never rebuild unnecessarily.
4. **Avoid watching in parent widgets** when only child widgets need the state.
5. **Use `ref.listen()`** for side effects (navigation, dialogs) — not `ref.watch()`.
6. **Use `ref.read()`** inside callbacks (onPressed) — never `ref.watch()`.

---

## Migration patterns

### Provider → Riverpod migration

1. Add `riverpod` + `flutter_riverpod` to pubspec.yaml alongside `provider`.
2. Wrap `MaterialApp` with `ProviderScope` (replaces `MultiProvider`).
3. Migrate one feature at a time: create Riverpod provider, remove Provider equivalent.
4. Replace `Consumer`/`context.watch()` with `ConsumerWidget`/`ref.watch()`.
5. Migrate repositories and services to Riverpod providers last.
6. Remove `provider` package when all migrations complete.

### GetX → Riverpod migration

1. Identify all `GetxController` classes → migrate to `Notifier/AsyncNotifier`.
2. Replace `Get.find<>()` → Riverpod `ref.read(provider)`.
3. Replace `Obx(()=>)` → `ConsumerWidget` + `ref.watch()`.
4. Replace `Get.to()` / `Get.toNamed()` → `go_router` routes.
5. Remove `GetMaterialApp` → use `MaterialApp.router`.
6. Remove `GetX` package entirely.

---

## Anti-pattern detection

- `ref.watch()` inside callbacks or event handlers (use `ref.read()`)
- Providers defined inside widget `build()` methods
- Watching entire state objects when only one field is needed
- `setState()` for state that crosses widget boundaries
- Using `BuildContext` inside Notifiers
- Async operations without `mounted` check (in widget callbacks)
- Multiple providers for the same domain with no clear boundary
- GetX controllers used anywhere

---

## Uncertainty protocol

- `High` (≥ 0.80): requirements clear, solution deterministic
- `Medium` (0.60–0.79): team familiarity or migration complexity unclear
- `Low` (< 0.60): conflicting requirements or unknown existing codebase size

---

## Cross-skill handoff payload

Use the standard payload from `../../AGENTS.md`.
Set `requesting_skill` to `flutter-state-management`.

---

## Output contract

Follow global section order from `../../AGENTS.md`. Also include:

- `State classification`
- `Recommended solution with justification`
- `Provider/notifier tree design`
- `Rebuild optimization strategy`
- `Migration plan (if applicable)`
- `Test strategy for state`

---

## Related resources

- `references/riverpod-patterns.md`
- `references/bloc-patterns.md`
- `references/state-selection-guide.md`
- `templates/notifier.dart`
- `templates/async-notifier.dart`
- `templates/bloc-feature.dart`

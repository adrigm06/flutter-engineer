---
name: flutter-navigation
description: >
  Lead authority for Flutter navigation and routing. Use when implementing go_router,
  deep links, auth guards, shell routes, nested navigation, or migrating from
  Navigator.push/pushNamed to declarative routing.
---

# Flutter Navigation Skill

## Purpose

Design and implement type-safe, deep-link-ready, guard-capable navigation for Flutter apps
using go_router as the mandatory routing solution.

## Scope and authority

Lead authority for:

- go_router configuration and route tree design
- deep link handling (Android/iOS/Web/desktop)
- authentication redirect guards
- shell routes (persistent bottom navigation)
- nested navigation flows
- route transitions and page animations
- typed route parameters
- modal and dialog navigation

Defers to:

- `flutter-architecture` for navigation placement within app structure
- `flutter-state-management` for navigation state synchronization

---

## When to use

- Setting up routing for a new Flutter app
- Adding deep link support
- Implementing auth guards and protected routes
- Designing bottom navigation with persistent subtrees (ShellRoute)
- Implementing multi-step flows (wizard, onboarding)
- Migrating from Navigator.push / Navigator.pushNamed
- Web URL routing configuration

---

## Mandatory routing stack

```yaml
dependencies:
  go_router: ^14.x  # Check latest at pub.dev
```

**No exceptions**: `Navigator.pushNamed` is prohibited. Use `context.go()` / `context.push()`.

---

## go_router architecture patterns

### App-level router configuration

```dart
// core/routing/app_router.dart
@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) => _handleRedirect(authState, state),
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
    routes: [
      // Auth routes (unauthenticated)
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const LoginScreen(),
        ),
      ),

      // Shell route — persistent bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => const EditProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

String? _handleRedirect(AuthState authState, GoRouterState state) {
  final isAuthenticated = authState is AuthAuthenticated;
  final isAuthRoute = state.matchedLocation.startsWith('/login') ||
      state.matchedLocation.startsWith('/register');

  if (!isAuthenticated && !isAuthRoute) return '/login';
  if (isAuthenticated && isAuthRoute) return '/';
  return null;
}
```

### Route constants (prevent magic strings)

```dart
// core/routing/routes.dart
abstract final class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const productDetail = '/products/:id';
  
  static String productDetailPath(String id) => '/products/$id';
}
```

### Typed routes (recommended for complex apps)

```dart
// Using go_router_builder for type-safe routes
@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData {
  const HomeRoute();
  @override Widget build(BuildContext context, GoRouterState state) => const HomeScreen();
}

@TypedGoRoute<ProductRoute>(path: '/products/:id')
class ProductRoute extends GoRouteData {
  const ProductRoute({required this.id});
  final String id;
  @override Widget build(BuildContext context, GoRouterState state) => ProductScreen(id: id);
}

// Usage — fully type-safe, no strings
const ProductRoute(id: '123').go(context);
```

---

## Deep link configuration

### Android

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data
    android:scheme="https"
    android:host="app.example.com" />
</intent-filter>
```

### iOS

```xml
<!-- ios/Runner/Info.plist -->
<key>FlutterDeepLinkingEnabled</key>
<true/>
```

### go_router deep link handling

go_router handles deep links automatically once native configuration is in place.
Test deep links:

```bash
# Android
adb shell am start -a android.intent.action.VIEW \
  -d "https://app.example.com/products/123" com.example.app

# iOS
xcrun simctl openurl booted "https://app.example.com/products/123"
```

---

## Shell route (persistent bottom navigation)

```dart
ShellRoute(
  builder: (context, state, child) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(state.matchedLocation),
        onDestinationSelected: (index) => _onNavTap(context, index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  },
  routes: [...], // Each tab is a sub-route
)
```

---

## Modal and dialog navigation

```dart
// ✅ Use push() + pop() for modals that return values
Future<void> _openEditDialog(BuildContext context) async {
  final result = await context.push<EditResult>('/edit-dialog');
  if (result != null) {
    // Handle result
  }
}

// ✅ Typed return value from pushed route
GoRoute(
  path: '/edit-dialog',
  pageBuilder: (context, state) => DialogPage(
    builder: (_) => const EditDialog(),
  ),
)
```

---

## Navigation from outside widgets (Riverpod integration)

```dart
// Using router notifier pattern — react to auth state changes
@riverpod
class RouterNotifier extends _$RouterNotifier implements Listenable {
  VoidCallback? _routerListener;

  @override
  void build() {
    // Listen to auth state and notify router to re-evaluate redirects
    ref.listen(authStateProvider, (_, __) => _routerListener?.call());
  }

  @override
  void addListener(VoidCallback listener) => _routerListener = listener;

  @override
  void removeListener(VoidCallback listener) => _routerListener = null;
}

// In GoRouter configuration:
GoRouter(
  refreshListenable: ref.watch(routerNotifierProvider.notifier),
  redirect: (context, state) => ...,
  routes: [...],
)
```

---

## Branching decision tree

### Branch A: app complexity

- **Simple app** (< 5 screens, no auth, no deep links):
  - go_router with simple flat routes
  - No ShellRoute needed
  - Basic typed parameters

- **Standard app** (auth, bottom nav, deep links):
  - go_router with ShellRoute + auth redirect guard
  - Typed routes via go_router_builder
  - Deep link configuration on both platforms

- **Complex app** (wizard flows, nested nav, web):
  - ShellRoute for persistent UI
  - Nested GoRouter segments for sub-flows
  - Web URL history integration

---

## Anti-pattern detection

- `Navigator.pushNamed()` usage → migrate to `context.go()`
- Hardcoded route strings scattered across codebase → use route constants
- Auth guard logic inside screens (show/hide content) → use router redirect
- Business logic in navigation callback → delegate to use case
- No deep link configuration for mobile apps
- Returning data via global state instead of `context.pop(result)` typed value
- Building route configuration inside `MaterialApp` without go_router

---

## Uncertainty protocol

- `High` (≥ 0.80): route tree and auth model defined
- `Medium` (0.60–0.79): partial route tree or auth model unclear
- `Low` (< 0.60): no route design started

---

## Cross-skill handoff payload

Use the standard payload from `../../AGENTS.md`.
Set `requesting_skill` to `flutter-navigation`.

---

## Output contract

Follow global section order from `../../AGENTS.md`. Also include:

- `Route tree diagram`
- `Auth guard logic`
- `Deep link configuration`
- `Typed route definitions`
- `ShellRoute design (if bottom nav needed)`

---

## Related resources

- `references/go-router-guide.md`
- `references/deep-link-setup.md`
- `references/typed-routes.md`
- `templates/app-router.dart`
- `templates/shell-route.dart`
- `templates/auth-redirect.dart`

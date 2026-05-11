# go_router Deep Dive

## Why go_router (not Navigator 2 raw API)

| Requirement | go_router | Navigator 2 raw |
|---|---|---|
| Deep link handling | ✅ Built-in | ❌ Manual (very complex) |
| Web URL bar integration | ✅ Automatic | ❌ Manual |
| Declarative routing | ✅ Route tree | ❌ State-heavy boilerplate |
| Guards / redirects | ✅ `redirect` callback | ❌ Requires RouterDelegate |
| Shell routes (persistent nav) | ✅ ShellRoute | ❌ Manual |
| Integration with Riverpod | ✅ `refreshListenable` | ❌ None |

**Rule**: go_router is the only approved navigation library. Navigator.pushNamed/push are prohibited.

---

## Route matching rules

### Exact match vs prefix

```
/home         → matches exactly /home
/products/:id → matches /products/abc, /products/123
/search       → matches only /search (not /search/results)
```

### Path parameters

```dart
// Define
GoRoute(
  path: '/products/:productId',
  builder: (context, state) => ProductScreen(
    id: state.pathParameters['productId']!,
  ),
)

// Navigate
context.go('/products/abc123');
context.go(AppRoutes.productDetailPath('abc123'));
```

### Query parameters

```dart
// Navigate with query params
context.go('/search?q=flutter&category=tools');

// Read in route
GoRoute(
  path: '/search',
  builder: (context, state) => SearchScreen(
    query: state.uri.queryParameters['q'],
    category: state.uri.queryParameters['category'],
  ),
)
```

---

## ShellRoute patterns

### Bottom navigation (persistent)

```dart
ShellRoute(
  builder: (context, state, child) => AppBottomNavShell(child: child),
  routes: [
    GoRoute(path: '/home', builder: ...),
    GoRoute(path: '/explore', builder: ...),
    GoRoute(path: '/profile', builder: ...),
  ],
)
```

### Nested shell (tabs within a section)

```dart
ShellRoute(
  navigatorKey: _rootKey,
  builder: (context, state, child) => MainShell(child: child),
  routes: [
    ShellRoute(
      navigatorKey: _settingsKey,
      builder: (context, state, child) => SettingsTabShell(child: child),
      routes: [
        GoRoute(path: '/settings/account', builder: ...),
        GoRoute(path: '/settings/notifications', builder: ...),
      ],
    ),
  ],
)
```

---

## Auth guard — complete pattern

### Multiple guards

```dart
String? _redirect(BuildContext context, GoRouterState state) {
  final auth = ref.read(authStateProvider);
  final onboarding = ref.read(onboardingStateProvider);
  final location = state.matchedLocation;

  // 1. Not authenticated → login
  if (auth is Unauthenticated) {
    if (location == '/login') return null; // Already there
    return '/login?redirect=${Uri.encodeComponent(location)}';
  }

  // 2. Authenticated but onboarding not complete
  if (auth is Authenticated && !onboarding.isComplete) {
    if (location.startsWith('/onboarding')) return null;
    return '/onboarding';
  }

  // 3. Authenticated → skip auth screens
  if (auth is Authenticated) {
    if (location == '/login' || location.startsWith('/onboarding')) {
      return '/home';
    }
  }

  return null;
}
```

### Redirect after login

```dart
// On login screen — redirect back after successful auth
GoRoute(
  path: '/login',
  builder: (context, state) {
    final redirectTo = state.uri.queryParameters['redirect'];
    return LoginScreen(redirectAfterLogin: redirectTo ?? '/home');
  },
)

// In login screen on success
void _onLoginSuccess(BuildContext context, String redirectTo) {
  context.go(redirectTo);
}
```

---

## Deep link setup

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<activity ...>
  <intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
      android:scheme="https"
      android:host="myapp.com" />
  </intent-filter>
</activity>
```

### iOS (`ios/Runner/Info.plist`)

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>myapp</string>   <!-- Custom scheme: myapp:// -->
    </array>
  </dict>
</array>
<!-- For universal links, also configure associated domains -->
```

### go_router deep link handling

go_router handles deep links automatically. Ensure:
1. Your route tree covers all deep-linkable paths
2. `redirect` guard handles authenticated vs unauthenticated states for deep links
3. Test with: `adb shell am start -W -a android.intent.action.VIEW -d "https://myapp.com/products/abc123"`

---

## Testing go_router

```dart
testWidgets('navigates to product detail', (tester) async {
  final router = GoRouter(
    routes: appRoutes,
    initialLocation: '/home',
    redirect: (_, state) => null, // Bypass auth guard in test
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authStateProvider.overrideWithValue(mockAuthenticatedState)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );

  // Trigger navigation
  router.go('/products/test-id');
  await tester.pumpAndSettle();

  expect(find.byType(ProductDetailScreen), findsOneWidget);
});
```

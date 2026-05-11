// go_router complete app router setup
// Replace route paths, screen names, and auth state with your implementation
// pubspec.yaml: go_router: ^14.x

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

// ===========================================================================
// NAVIGATOR KEYS
// ===========================================================================

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

// ===========================================================================
// ROUTE CONSTANTS — Never hardcode paths in widgets
// ===========================================================================

abstract final class AppRoutes {
  // Auth
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  // Shell (bottom nav)
  static const home = '/';
  static const explore = '/explore';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';

  // Feature
  static const productDetail = '/products/:id';
  static String productDetailPath(String id) => '/products/$id';

  static const checkout = '/checkout';
  static const orderConfirmation = '/checkout/confirmation/:orderId';
  static String orderConfirmationPath(String id) => '/checkout/confirmation/$id';
}

// ===========================================================================
// ROUTER PROVIDER
// ===========================================================================

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateProvider);
  // React to auth state changes automatically via refreshListenable
  final notifier = ref.watch(routerNotifierProvider.notifier);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: notifier,
    redirect: (context, state) => _handleRedirect(authState, state),
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
    routes: [
      // ── Unauthenticated routes ─────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // ── Authenticated shell (persistent bottom navigation) ─────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.explore,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ExploreScreen(),
            ),
            routes: [
              GoRoute(
                path: 'products/:id',
                parentNavigatorKey: _rootNavigatorKey, // Full screen, no shell
                builder: (context, state) => ProductDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
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

      // ── Full-screen flows (outside shell) ──────────────────────────────
      GoRoute(
        path: AppRoutes.checkout,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CheckoutScreen(),
        routes: [
          GoRoute(
            path: 'confirmation/:orderId',
            builder: (context, state) => OrderConfirmationScreen(
              orderId: state.pathParameters['orderId']!,
            ),
          ),
        ],
      ),
    ],
  );
}

// ===========================================================================
// AUTH REDIRECT GUARD
// ===========================================================================

String? _handleRedirect(AuthState authState, GoRouterState state) {
  final isAuthenticated = authState is AuthAuthenticated;
  final location = state.matchedLocation;

  final isAuthRoute = location.startsWith('/login') ||
      location.startsWith('/register') ||
      location.startsWith('/forgot-password');

  // Not authenticated → send to login (preserve intended destination)
  if (!isAuthenticated && !isAuthRoute) {
    return '${AppRoutes.login}?redirect=${Uri.encodeComponent(location)}';
  }

  // Already authenticated → skip auth screens
  if (isAuthenticated && isAuthRoute) return AppRoutes.home;

  // No redirect needed
  return null;
}

// ===========================================================================
// ROUTER NOTIFIER (reactive to auth state changes)
// ===========================================================================

@riverpod
class RouterNotifier extends _$RouterNotifier implements Listenable {
  VoidCallback? _routerListener;

  @override
  void build() {
    ref.listen(authStateProvider, (_, __) {
      _routerListener?.call();
    });
  }

  @override
  void addListener(VoidCallback listener) => _routerListener = listener;

  @override
  void removeListener(VoidCallback listener) => _routerListener = null;
}

// ===========================================================================
// APP SHELL (bottom navigation)
// ===========================================================================

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  static int _selectedIndex(String location) {
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(location),
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go(AppRoutes.home);
            case 1: context.go(AppRoutes.explore);
            case 2: context.go(AppRoutes.profile);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

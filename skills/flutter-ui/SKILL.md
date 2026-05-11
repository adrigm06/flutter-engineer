---
name: flutter-ui
description: >
  Lead authority for Flutter UI patterns, widget composition, theming, design systems,
  adaptive layouts, and accessibility-ready widget construction. Use when designing
  widget hierarchies, Material 3 theming, responsive/adaptive layouts, or custom widgets.
---

# Flutter UI Skill

## Purpose

Design composable, performant, accessible Flutter UI — from widget decomposition and
Material 3 theming to adaptive layouts across mobile, tablet, desktop, and web.

## Scope and authority

Lead authority for:

- widget decomposition and composition patterns
- Material 3 theming and design tokens
- adaptive and responsive layout design
- custom widget implementation
- animation and micro-interaction patterns
- design system structure and governance
- widget accessibility integration

Defers to:

- `flutter-performance` for rebuild optimization of UI
- `flutter-rendering` for custom painting and compositing
- `flutter-accessibility` for deep accessibility concerns
- `flutter-state-management` for state that flows through UI

---

## Widget composition rules

### Size limits

| Widget type | Max build() lines | Action if exceeded |
|---|---|---|
| Screen/Page widget | 60 lines | Extract sub-widgets |
| Reusable component | 80 lines | Extract sub-widgets or helpers |
| Primitive widget | 40 lines | Simplify or compose |

### Decomposition hierarchy

```
Screen (route-level widget)
  └── BodyLayout (layout composition)
        ├── SectionWidget (domain section)
        │     ├── ItemCard (reusable component)
        │     └── ItemCard
        └── EmptyStateWidget
```

### Rules

```dart
// ✅ Extract sub-widgets as separate classes (not private methods)
// Benefits: better DevTools visibility, const optimization, RepaintBoundary eligible

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) => Card(
    child: Column(children: [
      _OrderHeader(order: order),
      _OrderItems(items: order.items),
    ]),
  );
}

// ❌ Avoid private builder methods (can't be const, poor DevTools visibility)
Widget _buildOrderCard() => Card(...); // Bad pattern
```

---

## Material 3 theming (required from 2025+)

### Theme configuration

```dart
// core/theme/app_theme.dart
class AppTheme {
  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4), // Brand primary
      brightness: Brightness.light,
    ),
    typography: Typography.material2021(),
    textTheme: _buildTextTheme(),
    cardTheme: const CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
    ),
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.dark,
    ),
    typography: Typography.material2021(),
    textTheme: _buildTextTheme(),
  );

  static TextTheme _buildTextTheme() => const TextTheme(
    displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400),
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  );
}
```

### Design tokens approach

```dart
// core/theme/app_spacing.dart
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

// core/theme/app_radius.dart
abstract final class AppRadius {
  static const sm = Radius.circular(4);
  static const md = Radius.circular(8);
  static const lg = Radius.circular(12);
  static const xl = Radius.circular(16);
  static const full = Radius.circular(999);
}
```

---

## Adaptive layout patterns

### Responsive breakpoints

```dart
// core/layout/layout_breakpoints.dart
abstract final class LayoutBreakpoints {
  static const mobile = 600.0;
  static const tablet = 1024.0;
  static const desktop = 1440.0;
}

// Adaptive widget
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= LayoutBreakpoints.desktop) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= LayoutBreakpoints.tablet) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}
```

### Adaptive navigation pattern

```dart
// Bottom nav on mobile, NavigationRail on tablet, Drawer on desktop
class AdaptiveNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => switch (constraints.maxWidth) {
        >= 1024 => _DesktopLayout(child: child),
        >= 600  => _TabletLayout(child: child),
        _       => _MobileLayout(child: child),
      },
    );
  }
}
```

---

## Animation patterns

### Micro-interactions

```dart
// ✅ Use AnimatedContainer for simple transitions
AnimatedContainer(
  duration: const Duration(milliseconds: 200),
  curve: Curves.easeOut,
  width: isExpanded ? 200 : 100,
  decoration: BoxDecoration(
    color: isSelected
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(12),
  ),
)

// ✅ Respect reduced motion
Widget build(BuildContext context) {
  final reduceMotion = MediaQuery.of(context).disableAnimations;
  return AnimatedSwitcher(
    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
    child: currentWidget,
  );
}
```

### Page transitions

```dart
// Custom page transition (consistent with go_router)
Page<T> buildPage<T>({required Widget child}) => CustomTransitionPage<T>(
  child: child,
  transitionsBuilder: (context, animation, _, child) =>
      FadeTransition(opacity: animation, child: child),
  transitionDuration: const Duration(milliseconds: 250),
);
```

---

## Form widget patterns

```dart
// Feature-complete form with Formz
class LoginForm extends ConsumerWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(loginFormProvider);

    return Column(
      children: [
        TextFormField(
          key: const ValueKey('email_field'),
          decoration: InputDecoration(
            labelText: context.l10n.emailLabel,
            errorText: formState.email.displayError?.message,
          ),
          onChanged: (value) =>
              ref.read(loginFormProvider.notifier).updateEmail(value),
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          key: const ValueKey('login_button'),
          onPressed: formState.isValid
              ? () => ref.read(loginFormProvider.notifier).submit()
              : null,
          child: Text(context.l10n.loginButton),
        ),
      ],
    );
  }
}
```

---

## Anti-pattern detection

- Widget build() method > 80 lines → extract sub-widgets
- Private `_buildX()` methods creating widgets → extract as classes
- `Column(children: items.map(...).toList())` for lists → use ListView.builder
- Hardcoded colors/sizes not using ThemeData → use design tokens
- `MediaQuery.of(context)` in leaf widgets → use LayoutBuilder
- Missing `key:` on list items (prevents diffing issues)
- `Container` with no child or decoration (use SizedBox instead)
- `useMaterial3: false` in new projects → migrate to M3
- No `TextOverflow` handling on user-generated content
- Missing `Semantics` on custom interactive widgets

---

## Cross-skill handoff payload

Use the standard payload from `../../AGENTS.md`.
Set `requesting_skill` to `flutter-ui`.

---

## Output contract

Follow global section order from `../../AGENTS.md`. Also include:

- `Widget decomposition plan`
- `Theme and design token strategy`
- `Adaptive layout design`
- `Animation approach`
- `Accessibility compliance`

---

## Related resources

- `references/material3-guide.md`
- `references/adaptive-layouts.md`
- `references/animation-patterns.md`
- `references/design-tokens.md`
- `templates/screen-template.dart`
- `templates/custom-widget.dart`
- `templates/adaptive-layout.dart`

---
name: flutter-accessibility
description: >
  Lead authority for Flutter accessibility. Use when implementing screen reader support,
  semantics tree, focus traversal, contrast validation, reduced motion, touch targets,
  or keyboard navigation for any Flutter app targeting any platform.
---

# Flutter Accessibility Skill

## Purpose

Make Flutter apps usable by everyone — including users relying on screen readers,
keyboard navigation, switch access, large text, or reduced motion. Accessibility is
a release requirement, not an afterthought.

## Scope and authority

Lead authority for:

- semantics tree annotation (Semantics, MergeSemantics, ExcludeSemantics)
- screen reader compatibility (TalkBack, VoiceOver, Narrator)
- focus traversal and keyboard navigation
- contrast ratio validation (WCAG 2.1 AA minimum)
- touch target sizing
- text scaling and dynamic type
- reduced motion support
- web accessibility (ARIA via Flutter)

This skill applies to ALL platforms (mobile, web, desktop).

---

## Non-negotiable accessibility requirements

These apply to all apps. Exceptions require explicit documented justification.

| Requirement | Standard | Value |
|---|---|---|
| Minimum touch target | WCAG 2.5.5 | 48×48 logical pixels |
| Text contrast (body) | WCAG 1.4.3 AA | ≥ 4.5:1 |
| Text contrast (large) | WCAG 1.4.3 AA | ≥ 3:1 (≥18pt or ≥14pt bold) |
| No color-only information | WCAG 1.4.1 | Icon/text accompaniment required |
| Semantic labels | WCAG 1.1.1 | All interactive widgets labeled |
| Focus visible | WCAG 2.4.7 | Focus ring visible on all focusable elements |
| Text scaling | WCAG 1.4.4 | Layout functional at 200% text size |

---

## Semantics tree implementation

### Basic semantics

```dart
// ✅ Custom interactive widget — always add Semantics
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.isFavorite, required this.onTap});
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: isFavorite
        ? context.l10n.removeFromFavorites
        : context.l10n.addToFavorites,
    button: true,
    checked: isFavorite,
    child: GestureDetector(
      onTap: onTap,
      child: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        semanticLabel: '', // ❌ Suppress default Icon label (parent Semantics handles it)
      ),
    ),
  );
}
```

### MergeSemantics for grouped widgets

```dart
// ✅ Merge related widgets into single screen reader announcement
MergeSemantics(
  child: Row(
    children: [
      const Icon(Icons.star, color: Colors.amber),
      Text('4.5'),
      Text('(128 reviews)'),
    ],
  ),
)
// Screen reader announces: "4.5 128 reviews" as single unit
```

### ExcludeSemantics for decorative content

```dart
// ✅ Hide decorative or redundant elements from screen readers
ExcludeSemantics(
  child: Icon(Icons.circle, color: Colors.grey), // Visual decoration only
)
```

### SemanticsRole for custom components

```dart
// ✅ Assign semantic role for proper screen reader interpretation
Semantics(
  role: SemanticsRole.heading,
  child: Text('Section Title', style: Theme.of(context).textTheme.headlineMedium),
)
```

---

## Focus traversal

```dart
// ✅ Ensure logical tab order on forms
FocusTraversalGroup(
  policy: OrderedTraversalPolicy(),
  child: Column(
    children: [
      FocusTraversalOrder(
        order: const NumericFocusOrder(1),
        child: TextFormField(key: const Key('email')),
      ),
      FocusTraversalOrder(
        order: const NumericFocusOrder(2),
        child: TextFormField(key: const Key('password')),
      ),
      FocusTraversalOrder(
        order: const NumericFocusOrder(3),
        child: ElevatedButton(onPressed: _submit, child: const Text('Login')),
      ),
    ],
  ),
)

// ✅ Trap focus in modal dialogs
FocusScope(
  child: Dialog(
    child: _DialogContent(),
  ),
)
```

---

## Touch target sizing

```dart
// ✅ Ensure 48×48 minimum touch target
// Even if visual size is smaller, expand tap area
InkWell(
  onTap: onTap,
  child: Padding(
    padding: const EdgeInsets.all(12), // Expands touch area to ≥48px
    child: const Icon(Icons.close, size: 24),
  ),
)

// OR use SizedBox to enforce minimum size
SizedBox(
  width: 48,
  height: 48,
  child: IconButton(
    iconSize: 24,
    onPressed: onTap,
    icon: const Icon(Icons.close),
  ),
)
```

---

## Text scaling support

```dart
// ✅ Test at 200% text scale — fix overflow
// DO NOT cap textScaleFactor — respect user's OS setting
Text(
  userContent,
  maxLines: 3,           // ✅ Prevent unbounded overflow
  overflow: TextOverflow.ellipsis,
)

// ❌ Never hardcode text scale
MediaQuery(
  data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0), // PROHIBITED
  child: child,
)
```

---

## Color contrast validation

```dart
// Check contrast in design tokens
// Use https://webaim.org/resources/contrastchecker/

// ✅ High contrast pair (M3 default ColorScheme handles this)
color: Theme.of(context).colorScheme.onPrimary, // Text on primary
backgroundColor: Theme.of(context).colorScheme.primary,

// ❌ Custom colors without contrast validation
color: Colors.grey[400], // Against white background = 2.5:1 — FAILS
```

---

## Reduced motion

```dart
// ✅ Respect system reduced motion preference
@override
Widget build(BuildContext context) {
  final reduceMotion = MediaQuery.of(context).disableAnimations;

  return AnimatedOpacity(
    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
    opacity: isVisible ? 1.0 : 0.0,
    child: child,
  );
}
```

---

## Web accessibility

```dart
// ✅ Enable semantics for web (disabled by default for perf)
void main() {
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }
  runApp(const MyApp());
}

// ✅ Use standard widgets for automatic ARIA role mapping
// TabBar → role="tablist"
// MenuAnchor → role="menu"
// Table → role="table"
// For custom: use SemanticsRole enum
```

---

## Accessibility testing checklist

```
□ Navigate entire app with TalkBack (Android) or VoiceOver (iOS)
□ All interactive elements announced correctly
□ No focus traps outside of modals/dialogs
□ Tab key navigates all interactive elements on desktop/web
□ Test at 200% text scale — no overflow or clipping
□ Test at 0% animation (system reduced motion enabled)
□ Color contrast: validate all text against background
□ Custom widgets have Semantics labels
□ Error messages are announced (not just color changes)
□ Loading states announced ('Loading' or progress indicator)
□ Empty states announced ('No items found')
```

---

## Widget test for semantics

```dart
testWidgets('FavoriteButton has correct semantics', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: FavoriteButton(isFavorite: false, onTap: () {}),
    ),
  );

  final semantics = tester.getSemantics(find.byType(FavoriteButton));
  expect(semantics.label, 'Add to favorites');
  expect(semantics.hasFlag(SemanticsFlag.isButton), true);
  semantics.dispose();
});
```

---

## Anti-pattern detection

- Custom interactive widgets without Semantics labels → WCAG violation
- Tap targets smaller than 48×48 → WCAG 2.5.5 violation
- Color-only error indication → WCAG 1.4.1 violation
- Hardcoded textScaleFactor → WCAG 1.4.4 violation
- No focus visible on interactive elements → WCAG 2.4.7 violation
- Missing screen reader testing before release
- Decorative icons without ExcludeSemantics → noisy screen reader

---

## Cross-skill handoff payload

Use the standard payload from `../../AGENTS.md`.
Set `requesting_skill` to `flutter-accessibility`.

---

## Output contract

Follow global section order from `../../AGENTS.md`. Also include:

- `Semantics implementation plan`
- `Focus traversal design`
- `Contrast validation results`
- `Touch target compliance`
- `Accessibility test plan`

---

## Related resources

- `references/wcag-guide.md`
- `references/semantics-guide.md`
- `references/talkback-testing.md`
- `templates/accessible-widget.dart`
- `templates/accessibility-test.dart`

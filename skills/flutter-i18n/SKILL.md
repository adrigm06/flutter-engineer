---
name: flutter-i18n
description: >
  Lead authority for Flutter internationalization and localization. Use when setting up
  ARB files, implementing pluralization, RTL layout support, locale-aware formatting,
  typed translations with slang, or adding new locales to existing apps.
---

# Flutter i18n Skill

## Purpose

Implement comprehensive Flutter internationalization — type-safe translations, pluralization,
RTL layouts, locale-aware formatting, and governance for multi-locale apps.

## Scope and authority

Lead authority for:

- Flutter's built-in `flutter_localizations` + `intl` + ARB workflow
- slang code generation for type-safe translations
- pluralization and gender rules
- RTL layout support and testing
- locale-aware date, number, and currency formatting
- locale selection and persistence
- translation workflow governance

---

## Required setup (flutter_localizations + ARB)

### Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.x

flutter:
  generate: true  # Enables code generation from ARB files
```

### l10n.yaml configuration

```yaml
# l10n.yaml (project root)
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
use-deferred-loading: false  # Set true for web to defer locale loading
```

### ARB file structure

```json
// lib/l10n/app_en.arb
{
  "@@locale": "en",

  "appTitle": "My App",
  "@appTitle": {
    "description": "Application title shown in the app bar"
  },

  "loginButton": "Log in",
  "@loginButton": {
    "description": "Button label for login action"
  },

  "welcomeMessage": "Welcome, {name}!",
  "@welcomeMessage": {
    "description": "Welcome message with username",
    "placeholders": {
      "name": {
        "type": "String",
        "example": "John"
      }
    }
  },

  "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemCount": {
    "description": "Item count with pluralization",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },

  "lastSeen": "Last seen {date}",
  "@lastSeen": {
    "description": "Last seen date",
    "placeholders": {
      "date": {
        "type": "DateTime",
        "format": "MMMd",
        "isCustomDateFormat": "false"
      }
    }
  }
}
```

```json
// lib/l10n/app_es.arb
{
  "@@locale": "es",
  "appTitle": "Mi App",
  "loginButton": "Iniciar sesión",
  "welcomeMessage": "¡Bienvenido, {name}!",
  "itemCount": "{count, plural, =0{Sin elementos} =1{1 elemento} other{{count} elementos}}"
}
```

### MaterialApp setup

```dart
MaterialApp.router(
  title: 'My App',
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: ref.watch(localeProvider), // User-selected locale
  routerConfig: ref.watch(appRouterProvider),
)
```

### Usage in widgets

```dart
// Access via BuildContext extension
Text(context.l10n.welcomeMessage(user.displayName))
Text(context.l10n.itemCount(cart.itemCount))

// Extension for convenience (optional)
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
```

---

## slang (type-safe translations — recommended for large apps)

For apps with 50+ translation keys or complex plural/gender rules:

```yaml
dependencies:
  slang: ^3.x
  slang_flutter: ^3.x

dev_dependencies:
  slang_build_runner: ^3.x
```

```dart
// Generated from i18n/strings_en.i18n.json
// Usage — fully type-safe, no string keys:
Text(t.auth.loginButton)
Text(t.home.welcomeMessage(name: user.displayName))
Text(t.cart.itemCount(n: cart.count))
```

---

## Locale-aware formatting

```dart
// Always use intl package for locale-aware formatting
import 'package:intl/intl.dart';

class LocaleFormatter {
  LocaleFormatter(this.locale);
  final Locale locale;

  String formatDate(DateTime date) =>
      DateFormat.yMMMd(locale.toLanguageTag()).format(date);

  String formatCurrency(double amount, {String currency = 'USD'}) =>
      NumberFormat.currency(
        locale: locale.toLanguageTag(),
        symbol: currency,
      ).format(amount);

  String formatNumber(double value) =>
      NumberFormat.decimalPattern(locale.toLanguageTag()).format(value);

  String formatRelativeTime(DateTime dateTime) =>
      // Use timeago package for locale-aware relative time
      timeago.format(dateTime, locale: locale.languageCode);
}
```

---

## Locale selection and persistence

```dart
// Riverpod provider for user locale preference
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  static const _localeKey = 'user_locale';

  @override
  Locale? build() {
    // null = follow system locale
    final stored = ref.read(preferencesProvider).getString(_localeKey);
    if (stored == null) return null;
    final parts = stored.split('_');
    return Locale(parts[0], parts.length > 1 ? parts[1] : null);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    if (locale == null) {
      await ref.read(preferencesProvider).remove(_localeKey);
    } else {
      await ref.read(preferencesProvider).setString(_localeKey, locale.toLanguageTag());
    }
  }
}
```

---

## RTL (Right-to-Left) support

### Layout rules for RTL-compatible widgets

```dart
// ✅ Use Directionality-aware widgets (they handle RTL automatically)
Row()         // respects RTL direction
EdgeInsets.symmetric(horizontal: 16) // respects RTL

// ❌ Avoid directional widgets when RTL support is needed
Row(textDirection: TextDirection.ltr) // Forces LTR — breaks RTL
EdgeInsets.only(left: 16) // Should be EdgeInsetsDirectional.only(start: 16)

// ✅ RTL-aware padding
EdgeInsetsDirectional.only(start: 16, end: 8)

// ✅ RTL-aware positioning
AlignmentDirectional.centerStart // Not Alignment.centerLeft

// ✅ RTL-aware icons (flip icons that have direction meaning)
Icon(
  Icons.arrow_forward,
  textDirection: Directionality.of(context), // Auto-flips in RTL
)
```

### RTL testing

```dart
testWidgets('Layout is RTL-compatible', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'), // Arabic — RTL
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MyScreen(),
    ),
  );

  // Verify layout renders without overflow or alignment issues
  expect(tester.takeException(), isNull);
});
```

---

## Translation governance

### Rules for managing translations

1. **Never hardcode user-visible strings** in Dart files — all in ARB
2. **Add `@description`** to every ARB key (context for translators)
3. **Use descriptive key names** that communicate context (not `label1`, `button3`)
4. **Version control all ARB files** — treat as first-class source
5. **Run `flutter gen-l10n`** in CI to verify no missing translations
6. **Sync translations** before release (check all `app_*.arb` files are complete)

### Missing translation check in CI

```yaml
- name: Verify translations complete
  run: |
    flutter gen-l10n
    # Check for any missing keys in non-English ARB files
    dart run scripts/check_translations.dart
```

---

## Anti-pattern detection

- Hardcoded user-facing strings in widget files
- `Text('Hello \$name')` — string interpolation in UI (not translatable)
- `DateFormat('dd/MM/yyyy')` without locale (not locale-aware)
- `EdgeInsets.only(left:)` in apps targeting RTL locales
- `Alignment.centerLeft` instead of `AlignmentDirectional.centerStart`
- Missing pluralization (showing "1 items" for single item)
- Missing `@description` in ARB files (translators need context)
- ARB files not committed to source control

---

## Cross-skill handoff payload

Use the standard payload from `../../AGENTS.md`.
Set `requesting_skill` to `flutter-i18n`.

---

## Output contract

Follow global section order from `../../AGENTS.md`. Also include:

- `ARB file structure`
- `Locale setup (MaterialApp configuration)`
- `Pluralization examples`
- `RTL-specific considerations`
- `Translation governance plan`

---

## Related resources

- `references/arb-format-guide.md`
- `references/rtl-guide.md`
- `references/slang-setup.md`
- `templates/app-localizations-setup.dart`
- `templates/locale-provider.dart`
- `templates/arb-template.arb`

# Code Review Report

> **PR / Feature**: [PR #XXX — Feature name]
> **Reviewer**: [Name]
> **Date**: YYYY-MM-DD
> **Scope**: [Files reviewed / lines of code]

---

## Summary

| Severity | Count |
|---|---|
| 🔴 Critical (block merge) | 0 |
| 🟠 High (fix before merge) | 0 |
| 🟡 Medium (fix this sprint) | 0 |
| 🔵 Low / Nitpick | 0 |
| ✅ Positive patterns | 0 |

**Overall verdict**: ☐ Approved | ☐ Approved with minor changes | ☐ Changes required | ☐ Blocked

---

## 🔴 Critical — Block merge

_Findings that MUST be resolved before this PR can be merged._

### [C-001]: [Title]

- **File**: `lib/features/auth/data/auth_local_data_source.dart:42`
- **Finding**: Token stored in SharedPreferences instead of flutter_secure_storage.
- **Risk**: Any app with ADB access can extract the auth token.
- **Fix**:
  ```dart
  // ❌ Current
  await prefs.setString('access_token', token);
  
  // ✅ Required  
  await secureStorage.write(key: 'access_token', value: token);
  ```
- **Reference**: `skills/flutter-security/SKILL.md`

---

## 🟠 High — Fix before merge

_Important findings that must be addressed before this PR ships._

### [H-001]: [Title]

- **File**: `lib/features/home/presentation/screens/home_screen.dart:88`
- **Finding**: `ref.watch()` called inside `onPressed` callback.
- **Risk**: `ref.watch()` in callbacks causes incorrect behavior — state may be stale or trigger rebuild loops.
- **Fix**:
  ```dart
  // ❌ Current
  onPressed: () => ref.watch(cartProvider).clear(),
  
  // ✅ Required
  onPressed: () => ref.read(cartProvider.notifier).clear(),
  ```
- **Reference**: `skills/flutter-state-management/SKILL.md`

---

## 🟡 Medium — Fix this sprint

_Meaningful improvements that should be tracked but don't block merge._

### [M-001]: [Title]

- **File**: `lib/features/products/presentation/screens/product_list_screen.dart:35`
- **Finding**: Using `Column(children: products.map(...).toList())` for product list.
- **Risk**: Creates all items at once — causes jank with large lists.
- **Fix**: Replace with `ListView.builder`.

---

## 🔵 Low / Nitpick

_Minor style or improvement suggestions. Author discretion._

### [L-001]: Missing `const` constructor

- **File**: `lib/features/home/presentation/widgets/greeting_widget.dart:12`
- **Fix**: Add `const` to `SizedBox(height: 16)` — `const SizedBox(height: 16)`.

---

## ✅ Positive patterns to reinforce

_Good engineering decisions worth calling out explicitly._

- `FakeProductRepository` correctly implements stateful behavior — great pattern for tests.
- `select()` used for `userName` subscription — correct, prevents unnecessary rebuilds.
- Error boundary widget properly wraps the screen — good defensive design.

---

## Cross-skill escalations

| Finding | Escalated to | Severity |
|---|---|---|
| C-001 | `flutter-security` | Critical — release blocker |

---

## Suggested refactoring sequence (next sprint)

_Improvements beyond this PR that should be tracked as tech debt._

1. `ProductListScreen` has 94 lines in `build()` — extract sub-widgets.
2. Missing E2E test for checkout flow — add Patrol test.
3. `ProductRepository` caching strategy not implemented — schedule for next feature work.

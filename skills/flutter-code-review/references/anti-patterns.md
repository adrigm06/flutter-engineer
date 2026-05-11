# Flutter Anti-Patterns Reference

Quick reference for all patterns that must be flagged during code review.
Linked to the enforcement rules in `SKILL.md` and `../../PROJECT_RULES.md`.

---

## Critical (block release)

| Pattern | Why | Fix |
|---|---|---|
| Token in SharedPreferences | Extractable via ADB/backup | `flutter_secure_storage` |
| API key in source code | Leaks in binary, git history | CI secret injection |
| `--obfuscate` missing from release build | Readable class names enable reverse engineering | Add flag to build command |
| Cleartext HTTP in production | MITM attack vector | HTTPS + `usesCleartextTraffic=false` |
| `android:debuggable="true"` in release | Allows debugger attachment | Use Flutter release build (auto-sets) |

---

## High (fix before merge)

| Pattern | Why | Fix |
|---|---|---|
| GetX anywhere | Globally prohibited — poor safety, untestable | Migrate to Riverpod |
| `ref.watch()` in callbacks/onPressed | Stale state, rebuild loops | Use `ref.read()` in callbacks |
| Business logic in `build()` method | Untestable, tight coupling | Extract to Notifier/use case |
| Repository accessed from `build()` directly | Breaks layering, triggers re-fetch on rebuild | Use Riverpod provider |
| `Navigator.pushNamed()` | Bypasses go_router, breaks deep links | Use `context.go()` |
| BuildContext used after `await` without `mounted` check | Crash on widget disposal | Add `if (!mounted) return;` after every await |
| Missing `dispose()` for controllers | Memory leak | Implement `dispose()` in StatefulWidget |
| `setState()` for shared state | Anti-pattern for app state | Use Riverpod notifier |
| Domain model importing Flutter types | Breaks domain isolation | Use pure Dart in domain |
| No retry logic in Dio | Silent failures on transient errors | Add RetryInterceptor |
| Auth token logged (even partial) | Security violation | Remove all token logging |

---

## Medium (fix this sprint)

| Pattern | Why | Fix |
|---|---|---|
| `Column(children: list.map().toList())` for long lists | All items built at once — jank | `ListView.builder` |
| `MediaQuery.of(context)` in leaf widgets | Causes unnecessary parent rebuilds | Use `LayoutBuilder` locally |
| Global `screens/`, `widgets/`, `models/` directories | Defeats feature isolation | Migrate to feature-first |
| Feature imports another feature directly | Hidden coupling | Route through core or app DI |
| Provider defined inside widget `build()` | Recreated every build — broken behavior | Move to provider file |
| No `key` on list items | Diffing fails, animations break | Add `ValueKey(item.id)` |
| `IntrinsicHeight`/`IntrinsicWidth` in scroll paths | Expensive layout computation | Redesign layout |
| `Opacity` widget for static decoration | Creates unnecessary compositing layer | Use `Color.withOpacity()` |
| `ClipRRect` for visual decoration | Creates Clip layer | Use `BoxDecoration.borderRadius` |
| Missing error state in `when()` handler | Silently drops errors | Handle `error:` in AsyncValue.when |
| `dynamic` return type from API methods | Type safety lost | Use typed DTO models |
| No timeout on Dio | Requests hang indefinitely | Set `connectTimeout`/`receiveTimeout` |
| `DateTime.now()` in testable code | Non-deterministic tests | Inject `Clock` |
| `print()` in production code | Leaks info, performance | Use `logging` package |

---

## Low / Nitpick

| Pattern | Fix |
|---|---|
| Missing `const` constructors | Add `const` where applicable |
| `Container` with no child or decoration | Replace with `SizedBox` |
| `SizedBox` used as spacer with no size | Remove or use `Spacer()` / `Gap()` |
| Widget `build()` method > 60 lines | Extract sub-widgets as classes |
| Private `_buildX()` methods creating widgets | Extract as standalone widget classes |
| Hardcoded color values (not from ThemeData) | Use design tokens / `Theme.of(context)` |
| Missing `@override` annotation | Add annotation |
| Unused import | Remove |
| Missing semicolons after `}` in Dart | Dart style — no semicolons after blocks |

---

## Testing-specific anti-patterns

| Pattern | Why | Fix |
|---|---|---|
| `sleep()` in tests | Flaky — timing-dependent | Use `fakeAsync` / `pumpAndSettle` |
| `DateTime.now()` in test data | Non-deterministic | Use `Clock.fixed()` |
| Real network calls in unit/widget tests | Slow, flaky, environment-dependent | Mock at repository boundary |
| Mocking everything (including repos) | Fakes are better for stateful behavior | Use `Fake*` for repositories |
| Goldens updated blindly without review | Visual regressions silently accepted | Require visual diff review |
| Missing `tearDown` / `container.dispose()` | Test pollution across tests | Always dispose in tearDown |
| Tests asserting implementation details | Brittle — breaks on refactor | Test behavior and contracts |
| No test for failure paths | Only happy path tested | Add error case tests |

---

## Architecture-level anti-patterns

| Pattern | Why | Fix |
|---|---|---|
| God widget (1 screen widget, everything in it) | Untestable, unmaintainable | Decompose into features/components |
| Repository calling another repository | Creates coupling | Use use case to orchestrate |
| ViewModel containing HTTP client | Violates layering | Move to data source |
| Riverpod providers with circular dependencies | Deadlock / infinite build | Refactor dependency direction |
| Feature package importing another feature package | Hidden coupling | Route through app-level DI |
| `async void` methods (not event handlers) | Uncaught exceptions disappear | Use `Future<void>` + proper error handling |

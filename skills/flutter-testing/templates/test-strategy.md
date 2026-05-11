# Test Strategy Template

> **Feature / Module**: [Name]
> **Author**: [Name]
> **Date**: YYYY-MM-DD

---

## Critical user journeys (CUJ)

_List the flows that must NEVER fail. These dictate E2E coverage._

| Journey | Risk level | E2E required? |
|---|---|---|
| User signs in successfully | Critical | ✅ Yes |
| User signs in with invalid credentials | High | ✅ Yes |
| [Feature] happy path | High | ✅ Yes |
| [Feature] error recovery | Medium | ⚠️ Optional |

---

## Test pyramid allocation

| Layer | Target % | Tool | Focus |
|---|---|---|---|
| Unit | 70% | flutter_test + mocktail | Domain, application, data layer logic |
| Widget | 20% | flutter_test | Screens, reusable components, state integration |
| Golden | 5% | Alchemist | Design system, brand-critical screens |
| E2E | 5% | Patrol | Critical user journeys listed above |

---

## Domain layer test plan

| Class | What to test | Priority |
|---|---|---|
| `FeatureNameModel` | Value equality, copyWith | High |
| `FeatureNameRepositoryImpl` | Success path, error mapping | High |
| `FeatureNameNotifier` | build, refresh, delete, error rollback | High |
| `[UseCase]` | All input variations, error handling | High |

---

## Widget test plan

| Screen / Widget | States to cover | Priority |
|---|---|---|
| `FeatureNameScreen` | loading, success, empty, error | High |
| `FeatureNameCard` | default, selected, disabled | Medium |
| Form validation | valid, invalid, submitting, submitted | High |
| Error state | message display, retry button | High |

---

## Accessibility test plan

- [ ] Semantics: all interactive elements have labels
- [ ] Text scale 200%: no overflow or clipping
- [ ] Focus traversal: logical tab order
- [ ] Color-only information: test with color blindness simulation

---

## What NOT to test

| Item | Reason |
|---|---|
| `go_router` routing logic | Tested by go_router package itself |
| Flutter widget rendering | Handled by golden tests |
| Platform channel internals | Tested via plugin-level integration tests |
| Third-party SDK behavior | Out of scope — mock at service boundary |
| Trivial getters/setters | No meaningful logic to verify |

---

## Flakiness controls

| Risk | Mitigation |
|---|---|
| Animation timing | Use `pumpAndSettle()` or explicit `pump(duration)` |
| Non-deterministic IDs | Use fixed IDs in test fixtures |
| Time-dependent logic | Inject `Clock` — use `Clock.fixed()` in tests |
| Network calls | Replace with Fake/Mock at repository boundary |
| File system | Use in-memory Drift database or temporary path |

---

## Coverage gate

| Layer | Target | Current |
|---|---|---|
| Domain layer | ≥ 90% | — |
| Application layer | ≥ 90% | — |
| Data layer | ≥ 80% | — |
| Presentation layer | ≥ 70% | — |
| Overall | ≥ 80% | — |

---

## CI integration

```bash
# Run full test suite with coverage
flutter test --coverage --reporter=github

# Check coverage gate
dart run tool/check_coverage.dart --min=80
```

Golden tests run on `ubuntu-latest` only (deterministic font rendering).
E2E (Patrol) runs on merge to `main` only (slow, requires emulator).

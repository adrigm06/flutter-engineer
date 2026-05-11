# ADR — Architecture Decision Record

> **Number**: ADR-XXX
> **Title**: [Short title, e.g. "Adopt Riverpod 3 for state management"]
> **Date**: YYYY-MM-DD
> **Status**: Proposed | Accepted | Deprecated | Superseded by ADR-YYY

---

## Context

_What situation or problem forces this decision? Include team size, app complexity,
current pain points, and any time constraints._

Example:
> The app currently uses Provider 6 for state management. As the team has grown to
> 6 engineers and the app has 18 features, we're experiencing recurring issues with
> missing ChangeNotifier disposals and difficulty testing providers in isolation.
> We need a more scalable, testable state management solution.

---

## Decision

_State the decision clearly and precisely._

Example:
> We will migrate from Provider to Riverpod 3 (with code generation) as the sole
> state management solution. Migration will be feature-by-feature over 6 sprints.
> New features will use Riverpod exclusively from now.

---

## Alternatives considered

| Option | Pros | Cons | Rejected reason |
|---|---|---|---|
| Keep Provider | Zero migration cost | Scalability ceiling, poor compile-time safety | Doesn't solve root problems |
| flutter_bloc | Explicit event modeling | Higher boilerplate, event-driven model doesn't fit our domain | Overkill for our CRUD-dominant flows |
| GetX | Minimal boilerplate | No compile-time safety, anti-patterns baked in, untestable | Non-negotiable prohibition |
| **Riverpod 3** | Compile-time DI, testable, type-safe | Migration cost | **Selected** |

---

## Consequences

### Positive

- Compile-time dependency graph — no runtime `ProviderNotFoundException`
- `ProviderContainer` enables pure Dart unit tests with no widget tree
- `select()` enables granular subscriptions without custom `ChangeNotifier` gymnastics
- Consistent patterns across all 6 engineers

### Negative / Risks

- 6-sprint migration window with parallel Provider + Riverpod code
- Team needs training on Riverpod 3 code generation patterns
- Golden tests may need updates after state wiring changes

### Mitigation

- Pair programming sessions for first 2 features migrated
- ADR shared with team before migration starts
- Feature-flag new flows until fully migrated and tested

---

## Implementation notes

_Concrete steps, code patterns, or references that inform implementation._

- Follow `skills/flutter-state-management/SKILL.md` for Riverpod patterns
- Use `@riverpod` annotation with `build_runner` for code generation
- Existing Provider code: wrap with adapter until migrated (do not mix in same feature)
- Coverage requirement: each migrated Notifier must have ≥ 90% unit test coverage

---

## References

- [Riverpod 3 docs](https://riverpod.dev)
- [skills/flutter-state-management/SKILL.md](../../flutter-state-management/SKILL.md)
- [DECISION_MATRIX.md — State Management](../../../DECISION_MATRIX.md)

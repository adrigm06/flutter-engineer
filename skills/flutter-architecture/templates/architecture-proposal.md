# Architecture Proposal

> **Proposal for**: [Project / Feature name]
> **Author**: [Team / Engineer]
> **Date**: YYYY-MM-DD
> **Status**: Draft | Under Review | Approved | Rejected

---

## Executive summary

_2–3 sentence summary of the proposed architecture and why it fits this context._

---

## Context assessment

| Dimension | Current state | Trend |
|---|---|---|
| Team size | X engineers | Growing / Stable / Shrinking |
| App complexity | Low / Medium / High | Growing |
| Domain richness | CRUD / Event-driven / Complex | — |
| Regulatory constraints | None / PCI / HIPAA / GDPR | — |
| Offline requirements | None / Basic / Mission-critical | — |
| Build / test pain | None / Some / Severe | — |
| Migration risk tolerance | Low / Medium / High | — |

---

## Proposed architecture style

**Selected**: [Clean Architecture / Vertical Slice / Modular Monolith / Package-First]

**Justification**:
_Explain why this style fits the context assessment above. Reference the tradeoff table
from `references/architecture-styles.md`._

---

## Proposed folder structure

```
lib/
  features/
    [feature_a]/
      presentation/
      domain/
      data/
    [feature_b]/
      ...
  core/
    network/
    storage/
    routing/
    di/
    theme/
```

_Show the full proposed tree if the project has specific constraints._

---

## Layer responsibilities

| Layer | What it owns | What it does NOT own |
|---|---|---|
| `domain/` | Business rules, entities, repo interfaces | Framework code, HTTP, DB |
| `data/` | Repo implementations, DTOs, data sources | Business logic, UI |
| `presentation/` | Screens, widgets, ViewModels/Notifiers | Direct API calls, DB queries |
| `core/` | Network client, DB setup, routing config | Feature business logic |

---

## Dependency rules

_Copy and adapt from `references/dependency-rules.md` for this specific project._

**Allowed**:
```
presentation → domain
data → domain
application → domain
core → external packages
```

**Forbidden**:
```
domain → anything Flutter or platform
presentation → data implementations
feature_a → feature_b directly
```

---

## State management approach

**Selected**: [Riverpod 3 / flutter_bloc / Signals]

**Pattern**: [Notifier / AsyncNotifier / Bloc + sealed events]

_Reference `skills/flutter-state-management/SKILL.md` for rationale._

---

## Data persistence approach

**Selected**: [Drift / Isar / SharedPreferences / flutter_secure_storage]

_Reference `skills/flutter-storage/SKILL.md` for rationale._

---

## Navigation approach

**Selected**: go_router

_Reference `skills/flutter-navigation/SKILL.md` for configuration._

---

## Migration plan (if applicable)

| Phase | Scope | Duration | Rollback |
|---|---|---|---|
| Phase 1 | Extract `core/` infrastructure | 1 sprint | Revert files — no breaking changes |
| Phase 2 | Migrate `auth` feature to feature-first | 1 sprint | Revert auth folder, keep old |
| Phase 3 | Migrate remaining features (N per sprint) | N sprints | Per-feature revert |
| Phase 4 | Remove legacy flat structure | 1 sprint | No rollback — only after full coverage |

---

## Risks and mitigations

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Team unfamiliar with Clean Architecture | Medium | High | Pairing + ADR + knowledge transfer |
| Migration slows feature delivery | High | Medium | Feature-flag new flows, migrate in background |
| Test coverage drops during migration | Medium | High | Require ≥ 80% coverage before merge |

---

## Confidence

**Overall**: [High / Medium / Low]

**Missing information that could change this proposal**:
- _[e.g., confirmed team size in 6 months]_
- _[e.g., regulatory requirements finalized]_

---

## Decision requested

[ ] Approve as proposed
[ ] Approve with modifications (specify below)
[ ] Request more information (specify below)
[ ] Reject (specify reason below)

**Comments / modifications**:

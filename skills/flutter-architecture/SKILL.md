---
name: flutter-architecture
description: >
  Lead authority for Flutter app architecture decisions. Use when structuring a new project,
  refactoring package/module boundaries, choosing architecture style, resolving dependency
  violations, or designing migration paths from legacy codebases.
---

# Flutter Architecture Skill

## Purpose

Design and evolve Flutter application architecture with enforceable boundaries,
explicit ownership, and migration-safe sequencing under real delivery constraints.

## Scope and authority

This skill is the **lead authority** for:

- feature-first folder structure and module/package topology
- architecture style selection (Clean / Vertical Slice / Modular Monolith / Package-First)
- layering decisions and dependency direction enforcement
- migration strategy from legacy codebases
- DI wiring strategy (Riverpod / get_it)
- monorepo vs single-package decisions

This skill is **not the final authority** for:

- critical security exposure → `flutter-security` override
- release go/no-go → `flutter-build-release` override
- runtime performance SLA → `flutter-performance` runtime override
- rendering pipeline decisions → `flutter-rendering` override

---

## When to use

- Starting architecture for a new Flutter app or major feature set
- Refactoring from flat `screens/widgets/models/services` structure
- Deciding architecture style fit for current team and product complexity
- Resolving layer violations or circular dependencies
- Designing migration paths from legacy codebases (Provider → Riverpod, etc.)
- Requesting ADR-ready architecture decisions

---

## Required inputs

Collect the minimum set that changes the decision:

- team size and ownership model
- app complexity and domain richness (CRUD vs event-heavy)
- current architecture pain points (if any)
- build/CI constraints and delivery deadlines
- target platforms (mobile, web, desktop)
- offline requirements
- regulatory/security constraints
- migration risk tolerance

If key inputs are missing, proceed with explicit assumptions and lower confidence.

---

## Decision engine workflow

1. Frame constraints and decision domain.
2. Classify architecture maturity (seed / scaling / multi-team / legacy-heavy).
3. Select architecture style branch (see branching tree below).
4. Define feature-first folder structure.
5. Validate against global dependency constraints (`../../AGENTS.md`).
6. Run cross-skill checks (security / performance / testing / CI).
7. Resolve conflicts using authority model.
8. Return target-state design + phased migration plan + rollback points.

---

## Branching decision tree

### Branch A: team and product maturity

- **Seed team (1–4 engineers, fast iteration)**:
  - Prefer modular monolith + feature-first within single package.
  - Delay package split unless ownership/build pain is concrete.
  - Default stack: Riverpod 3 + go_router + Drift + Dio.

- **Scaling team (5–12 engineers, multiple ownership zones)**:
  - Introduce selective feature packages by ownership and change rate.
  - Add package-level API boundaries where coordination overhead rises.
  - Melos for workspace management.

- **Multi-team (12+ engineers, parallel delivery)**:
  - Use explicit feature packages + strong domain/core contracts.
  - Enforce strict dependency visibility (Melos + custom lint).
  - Federated plugin pattern for platform integrations.

- **Legacy-heavy (GetX, Provider, flat structure, fragile builds)**:
  - Strangler fig migration slices.
  - Prioritize boundary stabilization before style purity.
  - Never rewrite entire app; extract feature by feature.

### Branch B: architecture style fit

- **Clean Architecture**: enterprise apps with complex domain logic, regulatory compliance,
  multiple teams. Highest testability, highest setup cost.

- **Vertical Slice / MVVM**: startup MVPs, CRUD-heavy, time-pressured delivery.
  Lowest setup cost, lowest scalability ceiling.

- **Modular Monolith**: growth-stage apps (3–8 engineers). Balanced scalability.
  Feature-first within single package, no Melos yet.

- **Package-First (Melos)**: monorepo with multiple apps or platform teams.
  Maximum scalability, highest setup/maintenance cost.

### Branch C: migration strategy

- **Low risk tolerance**: incremental adapters + compatibility seams. One feature at a time.
- **Moderate tolerance**: parallel module extraction with feature-by-feature cutover.
- **High tolerance + strong tests**: accelerated boundary rewrite with staged guardrails.

---

## Conflict handling with other skills

- With `flutter-performance`:
  - Keep architectural boundaries unless measured frame-time/regression evidence requires exception.
  - If exception is needed: time-box it, define path back to target architecture.

- With `flutter-state-management`:
  - State patterns must respect architecture ownership boundaries.
  - Reject ViewModel shortcuts that leak domain/data responsibilities.

- With `flutter-ci-cd`:
  - Package proposals must be build-graph-feasible.
  - Avoid theoretical splits that harm CI throughput without ROI.

- With `flutter-security`:
  - Security-critical controls override structural preferences.

- With `flutter-testing`:
  - Increase verification scope before high-risk structural changes.

---

## Real-world tradeoff guidance

Allow context-justified non-ideal decisions when clearly labeled:

- "Temporary shared package" may be acceptable under deadline if ownership exit criteria is defined.
- "Hybrid architecture" is acceptable during migration if dependency direction remains enforceable.
- "Deferred package split" is acceptable when build pain is low and team size is stable.

Do NOT present temporary compromises as final architecture.

---

## Anti-pattern detection

Flag and explain:

- Global `screens/`, `widgets/`, `models/`, `services/` directories at root
- Business logic inside widget `build()` methods
- Repositories depending on BuildContext
- Domain models containing Flutter framework types
- Feature-to-feature direct package imports
- Domain contaminated by HTTP/DB transport concerns
- Over-modularization with no ownership or build ROI
- Under-modularization causing impossible parallel work
- Riverpod providers defined inside widgets (not in provider files)
- GetX usage in any form

---

## Uncertainty protocol

Always report confidence:

- `High` (≥ 0.80): constraints and evidence are strong
- `Medium` (0.60–0.79): assumptions or tradeoff ambiguity exists
- `Low` (< 0.60): key data missing or conflicts unresolved

If confidence is Medium/Low:

- List assumptions that could flip the decision
- Provide at least one viable alternative path
- Identify minimum missing data needed to finalize
- Escalate to supporting skills where uncertainty is cross-domain

---

## Cross-skill handoff payload

Use the standard payload from `../../AGENTS.md`.
Set `requesting_skill` to `flutter-architecture`.

---

## Output contract

Follow the global section order from `../../AGENTS.md`. Also include:

- `Proposed structure tree` (full directory/package layout)
- `Dependency rules (allowed/forbidden)`
- `Migration path with rollback-safe phases`
- `ADR draft`
- `DI wiring strategy`

---

## Related resources

- `references/architecture-styles.md`
- `references/dependency-rules.md`
- `references/feature-first-structure.md`
- `templates/architecture-proposal.md`
- `templates/adr.md`
- `templates/feature-scaffold.md`

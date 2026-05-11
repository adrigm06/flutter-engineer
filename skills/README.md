# Domain Skill Catalog

All active domain skills in the `flutter-engineer` system.

## Active skills (20)

| Skill | SKILL.md path | Authority scope |
|---|---|---|
| flutter-architecture | `skills/flutter-architecture/SKILL.md` | Structural: module/package boundaries, dependency direction, layering |
| flutter-state-management | `skills/flutter-state-management/SKILL.md` | Provider selection, rebuild optimization, data flow |
| flutter-ui | `skills/flutter-ui/SKILL.md` | Widget composition, Material 3, adaptive layouts |
| flutter-navigation | `skills/flutter-navigation/SKILL.md` | go_router, deep links, auth guards, shell routes |
| flutter-performance | `skills/flutter-performance/SKILL.md` | Frame budget, jank, memory, startup, GC pressure |
| flutter-rendering | `skills/flutter-rendering/SKILL.md` | Impeller, raster/UI thread, layer tree, RepaintBoundary |
| flutter-testing | `skills/flutter-testing/SKILL.md` | Confidence strategy, coverage, test pyramid |
| flutter-security | `skills/flutter-security/SKILL.md` | **Global critical override**: exploitability, secrets, transport trust, PII |
| flutter-networking | `skills/flutter-networking/SKILL.md` | Dio, interceptors, retry, caching, offline networking |
| flutter-storage | `skills/flutter-storage/SKILL.md` | Drift, Isar, Hive CE, secure storage, migrations |
| flutter-offline-first | `skills/flutter-offline-first/SKILL.md` | Local-first, sync engine, conflict resolution |
| flutter-accessibility | `skills/flutter-accessibility/SKILL.md` | Semantics, screen readers, WCAG, focus, contrast |
| flutter-i18n | `skills/flutter-i18n/SKILL.md` | ARB, slang, RTL, pluralization, locale formatting |
| flutter-build-release | `skills/flutter-build-release/SKILL.md` | **Production gate authority**: go/no-go, signing, store submission |
| flutter-monorepo | `skills/flutter-monorepo/SKILL.md` | Melos workspace, package-first, dependency governance |
| flutter-platform-integration | `skills/flutter-platform-integration/SKILL.md` | Platform channels, FFI, native views, background execution |
| flutter-code-review | `skills/flutter-code-review/SKILL.md` | Severity synthesis across mixed concerns |
| flutter-debugging | `skills/flutter-debugging/SKILL.md` | Root-cause, incident triage, hypothesis narrowing |
| flutter-ci-cd | `skills/flutter-ci-cd/SKILL.md` | Pipeline correctness, coverage gates, artifact integrity |
| flutter-observability | `skills/flutter-observability/SKILL.md` | Crashlytics, logging, performance traces, analytics |

---

## Skill fallback protocol

If a skill referenced in the routing matrix is not found:

1. Check this catalog — verify the skill exists before routing.
2. If skill does NOT exist: fall back to the orchestrator reasoning from `SKILL.md` directly using available context, and note "domain skill not available" in the output block.
3. Do NOT invent behaviors from a non-existent skill.
4. Surface the missing skill as a gap in the output: `Skill gap: flutter-[domain] not available`.

---

## Planned / future skills (not yet implemented)

These are referenced in planning documents but do NOT have SKILL.md files.
Do NOT route to these — fall back to orchestrator reasoning.

| Skill | Status |
|---|---|
| flutter-ai-integration | Planned — not implemented |
| flutter-dependency-governance | Planned — not implemented |

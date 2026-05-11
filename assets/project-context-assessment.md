## project-context-assessment

Use this worksheet to assess the project before routing to domain skills.
Ask the user or infer from available context (files, past turns, project description).

---

### Step 1 — Project type

Choose the closest match:

| Signal | Type |
|---|---|
| No existing codebase, fresh start | Greenfield |
| Existing Flutter app, improving or migrating | Legacy modernization |
| Multiple teams, ownership boundaries, Melos workspace | Enterprise / multi-team |
| 1-3 engineers, shipping fast, time-critical | Startup / MVP |

**Inferred type**: [Greenfield | Legacy | Enterprise | Startup]

---

### Step 2 — Assess available context

Check which of the following the user has provided:

| Context | Available? |
|---|---|
| Existing codebase to analyze | ☐ |
| pubspec.yaml with dependencies | ☐ |
| Error messages, stack traces, or crash logs | ☐ |
| Performance metrics (DevTools, Crashlytics) | ☐ |
| Team size and ownership structure | ☐ |
| Target platforms (Android, iOS, Web, Desktop) | ☐ |
| Regulatory constraints (HIPAA, PCI, GDPR) | ☐ |
| CI/CD configuration | ☐ |

**Minimum context available**: ☐ Yes — proceed  ☐ No — apply no-context fallback protocol

---

### Step 3 — No-context fallback protocol

If the user provides NO project context (no code, no description, no signals):

1. Do NOT assume any specific architecture or stack.
2. Ask for the minimum context: "What stage is the project at, and what is the specific problem you're solving?"
3. If the user wants code immediately, use Greenfield defaults and label all assumptions explicitly.
4. Downgrade confidence to `Low (0.50)` until context is received.

**Greenfield default stack** (apply only when explicitly assumed):

```yaml
state_management: Riverpod 3 (riverpod_annotation + code generation)
navigation: go_router
networking: Dio + RetryInterceptor + AuthInterceptor
local_storage: Drift (SQLite) + flutter_secure_storage
architecture: Feature-first Clean Architecture (modular monolith)
testing: flutter_test + mocktail + Alchemist + Patrol
linting: very_good_analysis + DCM
observability: Firebase Crashlytics + logging package
ci: GitHub Actions + Melos
```

---

### Step 4 — Risk and priority calibration

| Dimension | Low risk | High risk |
|---|---|---|
| Regulatory data (PII, finance, health) | No sensitive data | HIPAA / PCI / GDPR applies |
| Production traffic affected | Dev/Staging only | Live users affected |
| Team familiarity with proposed change | High familiarity | New pattern/package/API |
| Reversibility of decision | Easily reversible | Hard to undo once shipped |

If ≥ 2 are High risk → require `High` or `Critical` evidence gates before final recommendation.

# flutter-engineer

> **Staff/Principal-level Flutter engineering skill for AI agents.**
> 
> A modular, authority-driven decision engine that enforces enterprise-grade engineering standards
> across every critical Flutter domain — from architecture to release.

---

## What this is

`flutter-engineer` is an **agentic skill system**, not a prompt collection.

It behaves as a Flutter Principal Engineer: classifying requests, routing them to the correct domain expert, resolving cross-domain conflicts using a deterministic authority model, and returning one integrated, production-grade engineering decision.

It is designed to be loaded by AI agent systems (e.g. Google Gemini, Claude, OpenAI Assistants) that support structured skill/prompt libraries.

---

## Structure

```
flutter-engineer/
├── SKILL.md                    # Root orchestrator — mode classification, routing, pre-response protocol
├── AGENTS.md                   # Global runtime rules — authority model, gates, output contracts
├── PROJECT_RULES.md            # Enforceable engineering standards (non-negotiables, defaults)
├── DECISION_MATRIX.md          # 12 contextual decision tables (architecture, state, storage, nav…)
├── assets/
│   ├── project-context-assessment.md  # Context worksheet — filled before routing
│   └── glossary.md                    # Definitions for all system terms
└── skills/                     # 20 self-contained domain skills
    ├── README.md               # Domain catalog + fallback protocol
    ├── flutter-architecture/
    │   ├── SKILL.md
    │   ├── references/         # Architecture styles, dependency rules, feature-first structure
    │   └── templates/          # ADR, architecture proposal, feature scaffold
    ├── flutter-state-management/
    │   ├── SKILL.md
    │   ├── references/         # Riverpod 3 patterns
    │   └── templates/          # Notifier, AsyncNotifier
    ├── flutter-security/
    │   ├── SKILL.md
    │   ├── references/         # Release hardening checklist
    │   └── templates/          # Security review report
    ├── flutter-testing/
    │   ├── SKILL.md
    │   ├── references/         # Fake repository patterns
    │   └── templates/          # Unit test, widget test, test strategy
    ├── flutter-networking/
    │   ├── SKILL.md
    │   └── templates/          # Dio ApiClient, repository-network
    ├── flutter-navigation/
    │   ├── SKILL.md
    │   ├── references/         # go_router deep dive
    │   └── templates/          # Complete app router
    ├── flutter-performance/
    │   ├── SKILL.md
    │   ├── references/         # Performance guide (frame budget, rebuilds, Isolate)
    │   └── templates/          # Performance audit template
    ├── flutter-storage/
    │   ├── SKILL.md
    │   └── templates/          # Drift database (tables, DAOs, migrations, WAL)
    ├── flutter-offline-first/
    │   ├── SKILL.md
    │   ├── references/         # Offline-first architecture (sync strategies, conflict resolution)
    │   └── templates/          # Sync engine (queue-based, idempotent)
    ├── flutter-ci-cd/
    │   ├── SKILL.md
    │   └── templates/          # GitHub Actions CI workflow, Melos workspace config
    ├── flutter-monorepo/
    │   ├── SKILL.md
    │   └── references/         # Melos guide
    ├── flutter-code-review/
    │   ├── SKILL.md
    │   ├── references/         # Flutter anti-patterns (Critical/High/Medium/Low)
    │   └── templates/          # Review report
    ├── flutter-build-release/
    │   ├── SKILL.md
    │   └── templates/          # Release checklist (quality, security, performance, store gates)
    ├── flutter-observability/
    │   ├── SKILL.md
    │   └── templates/          # App logger (structured logging + Crashlytics)
    ├── flutter-debugging/
    │   ├── SKILL.md
    │   └── templates/          # Debug investigation checklist
    ├── flutter-rendering/      SKILL.md
    ├── flutter-ui/             SKILL.md
    ├── flutter-accessibility/  SKILL.md
    ├── flutter-i18n/           SKILL.md
    └── flutter-platform-integration/  SKILL.md
```

---

## How it works

### 1. The agent receives a Flutter task

Any task related to Flutter/Dart development — architecture question, code review, debug, performance investigation, release decision.

### 2. SKILL.md classifies and routes

The orchestrator:
1. Assesses project context (Greenfield / Legacy / Enterprise / Startup)
2. Classifies the request mode (Design / Review / Generation / Debug / Optimize / Release)
3. Routes to the lead domain skill
4. Pulls constraints from materially relevant supporting skills
5. Resolves conflicts using the deterministic authority protocol

### 3. Domain skill executes

Each domain skill provides:
- Decision criteria and anti-patterns
- Enforcement rules and quantitative gates
- Code examples, references, and templates

### 4. Integrated output

Every response includes the compact output block:

```
Lead domain: flutter-architecture
Supporting domains: flutter-security, flutter-testing
Mode: Design
Top gates: coverage ≥ 80% [at-risk], no secrets in source [pass], layering enforced [pass]
Confidence: High (0.85)
Minimum extra evidence: team size, target platform count
Skill gaps: none
```

---

## Domain skills (20 active)

| Skill | Covers |
|---|---|
| **flutter-architecture** | Feature-first structure, Clean Architecture, migration strategies |
| **flutter-state-management** | Riverpod 3, AsyncNotifier, rebuild optimization |
| **flutter-ui** | Widget composition, Material 3, adaptive layouts, animations |
| **flutter-navigation** | go_router, shell routes, deep links, auth guards |
| **flutter-performance** | Frame budget, jank, memory, startup, Isolate patterns |
| **flutter-rendering** | Impeller, raster/UI thread, layer tree, RepaintBoundary |
| **flutter-testing** | Unit/widget/golden/E2E pyramid, Patrol, Alchemist |
| **flutter-security** | Secure storage, SSL pinning, obfuscation, binary hardening |
| **flutter-networking** | Dio, interceptors, retry, auth refresh, offline fallback |
| **flutter-storage** | Drift, Isar, migrations, WAL, encryption at rest |
| **flutter-offline-first** | Sync engine, conflict resolution, queue-based offline |
| **flutter-accessibility** | WCAG, semantics tree, TalkBack/VoiceOver, focus traversal |
| **flutter-i18n** | ARB, slang, pluralization, RTL, locale formatting |
| **flutter-build-release** | Flavors, obfuscation, staged rollouts, go/no-go gates |
| **flutter-monorepo** | Melos, package-first, federated plugins, versioning |
| **flutter-platform-integration** | MethodChannel, EventChannel, Dart FFI, native views |
| **flutter-code-review** | Severity rubrics, anti-pattern detection, cross-domain synthesis |
| **flutter-debugging** | Hypothesis-driven RCA, DevTools, Crashlytics triage |
| **flutter-ci-cd** | GitHub Actions, Melos scripts, quality gates, artifact signing |
| **flutter-observability** | Crashlytics, structured logging, analytics governance |

---

## Authority model

Conflicts between domain skills are resolved deterministically:

| Priority | Skill | Trigger |
|---|---|---|
| 1st | `flutter-security` | Any exploitability, PII, or secret exposure |
| 2nd | `flutter-build-release` | Production-blocking constraint |
| 3rd | `flutter-architecture` | Structural boundary violation |
| 4th | Lead skill by decision domain | All other cases |

---

## Non-negotiables (never violated)

```
❌ Secrets / JWTs in SharedPreferences
❌ Business logic in widget build() methods
❌ Direct feature-to-feature package dependencies
❌ Domain models with Flutter framework types
❌ print() in production code
❌ GetX (globally forbidden)
❌ Navigator.pushNamed (use go_router)
❌ async after BuildContext without mounted check
❌ Hard-coded API keys in source
```

---

## Default tech stack (Greenfield)

| Concern | Default |
|---|---|
| State management | Riverpod 3 + code generation |
| Navigation | go_router |
| Networking | Dio + interceptors |
| Local storage | Drift (SQLite) |
| Secure storage | flutter_secure_storage |
| Architecture | Feature-first Clean Architecture |
| Linting | very_good_analysis + DCM |
| Testing | flutter_test + mocktail + Alchemist + Patrol |
| Observability | Firebase Crashlytics + logging package |
| CI | GitHub Actions + Melos |

---

## Invocation examples

### Design mode
```
"How should I structure my Flutter app that has 5 features and a team of 4 engineers?"
→ Lead: flutter-architecture | Mode: Design
```

### Review mode
```
"Review this PR — here's the diff of the auth feature."
→ Lead: flutter-code-review | Supporting: flutter-security, flutter-testing | Mode: Review
```

### Generation mode
```
"Generate the scaffold for a new 'orders' feature with Riverpod and Drift."
→ Lead: flutter-architecture | Supporting: flutter-state-management, flutter-storage | Mode: Generation
```

### Debug mode
```
"My app crashes with a Null check operator error when navigating back from checkout."
→ Lead: flutter-debugging | Mode: Debug
```

### Optimize mode
```
"My product list scrolls at 40fps on a mid-range Android device."
→ Lead: flutter-performance | Supporting: flutter-rendering | Mode: Optimize
```

### Release mode
```
"Is this build ready to release to production?"
→ Lead: flutter-build-release | Supporting: flutter-security, flutter-ci-cd | Mode: Release
```



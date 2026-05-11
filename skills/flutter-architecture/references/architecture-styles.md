# Architecture Styles

## 1. Clean Architecture

**When**: enterprise SaaS, regulated industries (PCI/HIPAA), large teams (8+), complex domain logic.

### Layers

```
Presentation → Application → Domain ← Data
```

| Layer | Responsibility | Example contents |
|---|---|---|
| Presentation | UI, state, navigation | Screens, Notifiers, ViewModels |
| Application | Orchestrate use cases | SignInUseCase, CheckoutUseCase |
| Domain | Core business rules | User model, AuthRepository (interface), AuthFailure |
| Data | Implement domain contracts | AuthRepositoryImpl, AuthRemoteDataSource, UserDto |

### Tradeoffs

| Pro | Con |
|---|---|
| Maximum testability — domain has zero dependencies | High setup cost — many files per feature |
| Each layer replaceable independently | Overkill for CRUD-heavy apps |
| Scales to large teams without coupling | Use cases can be trivial pass-throughs |
| Explicit dependency inversion | Steeper onboarding curve |

### When to add the Application layer

Add `use_cases/` only when:
- The use case orchestrates multiple repositories
- Business logic must not live in the presentation layer
- Multiple entry points need the same business sequence (e.g., mobile + background worker)

Skip for simple CRUD — a Notifier calling a Repository is sufficient.

---

## 2. Vertical Slice / MVVM

**When**: startup MVPs, internal tools, CRUD-heavy apps, teams of 1–4, time pressure.

### Structure

```
features/
  auth/
    login_screen.dart          # UI
    login_view_model.dart      # Riverpod Notifier (business + state)
    auth_service.dart          # Thin data wrapper
    user.dart                  # Domain model
```

Everything for a feature in one folder. No strict layer separation.

### Tradeoffs

| Pro | Con |
|---|---|
| Fastest time-to-feature | Logic eventually leaks everywhere |
| Minimal boilerplate | Hard to scale beyond ~10 features |
| Easy to understand | Testability degrades over time |
| Great for prototyping | Migration to Clean is expensive |

---

## 3. Modular Monolith

**When**: growth-stage apps (3–8 engineers), need clear ownership but not ready for packages.

### Structure

Same as feature-first Clean Architecture, but with strict lint/rules enforcing module boundaries.
No Melos yet — single package, but strict folder contracts.

### Upgrade path

```
Modular Monolith → extract feature packages (Melos) when:
  - Team grows beyond 8 engineers
  - Feature ownership becomes painful to coordinate
  - Build times benefit from incremental package caching
```

---

## 4. Package-First (Melos Monorepo)

**When**: 12+ engineers, multiple product apps, platform team, microservices backend.

### Structure

```
apps/   → Flutter apps (depend on feature and core packages)
packages/
  core/ → shared infrastructure packages
  features/ → self-contained feature packages
  design_system/ → shared UI package
```

### Tradeoffs

| Pro | Con |
|---|---|
| Maximum team autonomy | High initial setup complexity |
| Independent package testing/caching | Melos lifecycle to manage |
| Parallel development without friction | Cross-package refactoring is hard |
| Shared packages across apps | Package versioning overhead |

---

## Migration paths

### Flat → Feature-First (any size)

1. Create `features/` directory
2. Move one feature at a time (auth first — highest isolation)
3. Create `core/` for shared infrastructure
4. Enforce no-global-`screens/` lint rule
5. Repeat per feature

### Feature-First → Modular Monolith

1. Add custom lint rules enforcing import boundaries
2. Document allowed/forbidden dependencies
3. Add CI dependency check

### Modular Monolith → Package-First

1. Install Melos
2. Extract `design_system` first (least dependencies)
3. Extract `core_network`, `core_storage` (infrastructure)
4. Extract features by ownership — start with most isolated
5. Update apps to depend on packages

---
name: flutter-monorepo
description: >
  Lead authority for Flutter monorepo architecture. Use when designing Melos workspaces,
  package-first architecture, federated plugins, shared packages, dependency governance,
  or managing multi-app Flutter monorepos.
---

# Flutter Monorepo Skill

## Purpose

Design and manage production-grade Flutter monorepos with Melos — package-first
architecture, clear ownership boundaries, federated plugins, shared packages, and
reproducible multi-app workspace builds.

## Scope and authority

Lead authority for:

- Melos workspace configuration and lifecycle scripts
- package-first architecture design
- shared package strategy (core_ui, core_network, design_system)
- feature package boundaries and ownership
- federated plugin architecture
- cross-package dependency governance
- versioning and changelog management

Defers to:

- `flutter-architecture` for feature-package boundary decisions
- `flutter-ci-cd` for CI pipeline using Melos

---

## When to use

- Setting up Melos for a new monorepo
- Splitting a large app into packages
- Designing shared package strategy
- Managing cross-package dependency updates
- Implementing federated plugin structure
- Versioning packages with conventional commits

---

## Melos workspace structure

```
my_workspace/
├── melos.yaml
├── pubspec.yaml          # Workspace root (no dependencies, just Dart)
├── apps/
│   ├── consumer_app/     # End-user Flutter app
│   │   └── pubspec.yaml  # Depends on feature_* and core_* packages
│   └── admin_app/        # Internal Flutter app
│       └── pubspec.yaml
├── packages/
│   ├── core/
│   │   ├── core_network/     # Dio client, interceptors
│   │   ├── core_storage/     # Drift, Isar setup
│   │   ├── core_auth/        # Auth repository interface + implementation
│   │   └── core_analytics/   # Analytics service
│   ├── design_system/        # Shared UI tokens, atoms, molecules
│   ├── features/
│   │   ├── feature_auth/     # Auth feature: presentation + application + domain
│   │   ├── feature_home/
│   │   ├── feature_checkout/
│   │   └── feature_profile/
│   └── plugins/
│       └── my_camera_plugin/ # Federated plugin
│           ├── my_camera_plugin/         # Dart interface
│           ├── my_camera_plugin_android/ # Android implementation
│           ├── my_camera_plugin_ios/     # iOS implementation
│           └── my_camera_plugin_platform_interface/
└── tools/                    # Internal Dart tools and scripts
```

---

## melos.yaml (production-ready configuration)

```yaml
name: my_workspace

sdkPath: auto  # Use local Flutter SDK

packages:
  - apps/**
  - packages/**
  - packages/core/**
  - packages/features/**
  - packages/plugins/**

ignore:
  - '**/.dart_tool/**'
  - '**/build/**'

scripts:
  # ────────── Core workflow ──────────
  bootstrap:
    run: melos bootstrap
    description: Bootstrap the workspace (pub get all packages)

  clean:
    run: melos exec -- flutter clean
    exec:
      concurrency: 5
    description: Clean all packages

  # ────────── Quality ──────────
  analyze:
    run: dart analyze --fatal-infos .
    exec:
      concurrency: 5
    description: Run static analysis on all packages

  format:
    run: dart format . --fix
    exec:
      concurrency: 5

  format:check:
    run: dart format . --check
    exec:
      concurrency: 5

  # ────────── Tests ──────────
  test:
    run: flutter test --coverage
    exec:
      concurrency: 3
    description: Run all tests

  test:unit:
    run: flutter test test/unit --reporter compact
    exec:
      concurrency: 4

  test:widget:
    run: flutter test test/widget --reporter compact
    exec:
      concurrency: 2

  test:golden:
    run: flutter test --tags golden
    exec:
      concurrency: 1
    description: Run golden tests (serial for deterministic rendering)

  test:update-goldens:
    run: flutter test --tags golden --update-goldens
    exec:
      concurrency: 1

  # ────────── Code generation ──────────
  gen:
    run: dart run build_runner build --delete-conflicting-outputs
    exec:
      concurrency: 1
    description: Run code generation (Riverpod, Drift, Freezed, slang)

  gen:watch:
    run: dart run build_runner watch --delete-conflicting-outputs
    exec:
      concurrency: 1

  # ────────── Builds ──────────
  build:android:dev:
    run: >
      flutter build apk --debug
      -t lib/main_dev.dart
      --flavor dev
      --dart-define=ENV=development
    packageFilters:
      scope: "consumer_app"

  build:android:release:
    run: >
      flutter build appbundle --release
      -t lib/main.dart
      --flavor prod
      --obfuscate
      --split-debug-info=build/symbols/
      --dart-define=ENV=production
    packageFilters:
      scope: "consumer_app"

  # ────────── Versioning ──────────
  version:
    run: melos version
    description: Bump versions using conventional commits

  publish:dry-run:
    run: dart pub publish --dry-run
    exec:
      concurrency: 1
    description: Dry-run publish all packages
```

---

## Package dependency rules (enforced by Melos + custom lint)

### Allowed dependency directions

```
apps/* → feature_*
apps/* → core_*
apps/* → design_system
feature_* → core_*
feature_* → design_system
core_* → (external packages only)
design_system → (external UI packages only)
```

### Forbidden dependency directions

```
feature_a → feature_b (direct)   # Route through app-level DI
core_* → feature_*               # Core must not depend on features
design_system → feature_*        # DS must not depend on features
apps/* → apps/* (cross-app)      # Apps are isolated
```

### Enforcing in CI

```bash
# Melos can enforce package constraints
melos analyze --concurrency=5 --fatal-warnings

# Custom script to check forbidden imports
dart run tools/check_dependency_rules.dart
```

---

## Shared package strategy

### core_network

```yaml
# packages/core/core_network/pubspec.yaml
name: core_network
dependencies:
  dio: ^5.x
  dio_cache_interceptor: ^3.x
  flutter_secure_storage: ^9.x
```

Exports: `ApiClient`, `AuthInterceptor`, `RetryInterceptor`, `NetworkException`

### core_storage

```yaml
name: core_storage
dependencies:
  drift: ^2.x
  isar: ^4.x
  shared_preferences: ^2.x
  flutter_secure_storage: ^9.x
```

Exports: `AppDatabase`, `SecureTokenStorage`, `PreferencesService`

### design_system

```yaml
name: design_system
dependencies:
  flutter:
    sdk: flutter
```

Exports: Design tokens (`AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`),
atoms (`AppButton`, `AppTextField`, `AppCard`), molecules.

### feature package structure

```
packages/features/feature_auth/
  lib/
    src/
      presentation/
        screens/
        widgets/
        view_models/
      application/
        use_cases/
      domain/
        models/
        repositories/  # interfaces
      data/
        repositories/  # implementations
        data_sources/
    feature_auth.dart  # Public API (barrel export)
  test/
  pubspec.yaml
```

---

## Federated plugin structure

```
packages/plugins/my_camera/
├── my_camera/                        # App-facing package
│   ├── lib/my_camera.dart            # Public API
│   └── pubspec.yaml
├── my_camera_platform_interface/     # Abstract interface
│   ├── lib/my_camera_platform_interface.dart
│   └── pubspec.yaml
├── my_camera_android/                # Android implementation
│   └── pubspec.yaml
└── my_camera_ios/                    # iOS implementation
    └── pubspec.yaml
```

---

## Versioning strategy

```yaml
# melos.yaml versioning config
command:
  version:
    message: "chore(release): publish packages\n\n{new_package_versions}"
    branch: main
    workspaceChangelog: true
    linkToCommits: true
    updateGitTagRefs: true
```

Conventional commits drive automatic version bumping:
- `feat:` → minor bump
- `fix:` → patch bump
- `feat!:` or `BREAKING CHANGE:` → major bump

---

## Anti-pattern detection

- Feature packages directly importing other feature packages
- Core packages depending on feature packages
- Melos not used for code generation lifecycle (missing `gen` script)
- Packages versioned manually (use melos version with conventional commits)
- Barrel exports exposing internal implementation details
- Single monolithic `packages/lib` containing all code (defeats monorepo purpose)
- No `packageFilters` on app-specific build scripts (runs on wrong packages)

---

## Cross-skill handoff payload

Use the standard payload from `../../AGENTS.md`.
Set `requesting_skill` to `flutter-monorepo`.

---

## Output contract

Follow global section order from `../../AGENTS.md`. Also include:

- `Workspace structure diagram`
- `melos.yaml configuration`
- `Package dependency rules`
- `Shared package strategy`
- `Versioning plan`

---

## Related resources

- `references/melos-guide.md`
- `references/package-first-architecture.md`
- `references/federated-plugins.md`
- `templates/melos.yaml`
- `templates/package-pubspec.yaml`
- `templates/feature-package-structure.md`

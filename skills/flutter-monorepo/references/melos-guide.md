# Melos Guide

## What is Melos?

Melos is the standard tooling for Flutter/Dart monorepos.
It manages: package bootstrapping, script orchestration, versioning, and publishing.

Install: `dart pub global activate melos`

---

## Bootstrap workflow

```bash
# First-time setup
melos bootstrap          # pub get in all packages (linked via symlinks)

# After adding a new package or changing pubspec.yaml
melos bootstrap

# Clean all (remove build artifacts, .dart_tool)
melos clean && melos bootstrap
```

---

## Running scripts

```bash
# Run a script across all packages
melos run test

# Run a script on specific packages only
melos run build:android:release --scope consumer_app

# Run in parallel (default if concurrency > 1 in melos.yaml)
melos run analyze

# Filter by package path
melos exec --scope "packages/features/**" -- flutter test
```

---

## Common workflows

### Start new feature

```bash
# 1. Bootstrap (ensure clean state)
melos bootstrap

# 2. Generate code (if entity/provider changed)
melos run gen

# 3. Run tests for changed package only
melos run test --scope feature_auth

# 4. Run full quality gate before committing
melos run ci
```

### After pulling changes

```bash
# Always re-bootstrap after pulling (dependencies may have changed)
melos bootstrap
melos run gen  # Regenerate if pubspec or annotations changed
```

### Updating dependencies

```bash
# Check what's outdated
melos run deps:check

# Upgrade a single package carefully
cd packages/core/core_network
flutter pub upgrade dio --major-versions

# Run tests to confirm no breakage
melos run test --scope core_network
```

---

## Versioning with conventional commits

Melos reads commit history to determine version bumps:

| Commit prefix | Version bump | Example |
|---|---|---|
| `feat:` | Minor (1.0.0 → 1.1.0) | New feature, backward-compatible |
| `fix:` | Patch (1.0.0 → 1.0.1) | Bug fix |
| `feat!:` or `BREAKING CHANGE:` | Major (1.0.0 → 2.0.0) | Breaking API change |
| `chore:`, `docs:`, `style:` | No bump | Non-functional changes |

```bash
# Preview what will be bumped (dry run)
melos version --dry-run

# Apply version bumps and create changelog entries
melos version

# This will:
# - Bump versions in affected pubspec.yaml files
# - Generate CHANGELOG.md entries
# - Create git tags
```

---

## Package dependency linking

Melos uses path dependencies during development via symlinks:

```yaml
# In feature_auth/pubspec.yaml
dependencies:
  core_network:
    path: ../../core/core_network  # Path during development
```

Melos resolves this automatically. Published packages use version constraints.

---

## Useful melos CLI flags

| Flag | Effect |
|---|---|
| `--scope <pattern>` | Run only on matching package names |
| `--ignore <pattern>` | Skip matching package names |
| `--since <branch>` | Run only on packages changed since branch |
| `--diff <ref>` | Run on packages with git changes vs ref |
| `--concurrency <n>` | Override script concurrency |
| `--fail-fast` | Stop on first failure |

### Run only on changed packages (CI optimization)

```bash
# Only test packages changed vs main
melos run test --since origin/main
```

---

## Troubleshooting

| Issue | Fix |
|---|---|
| `pub get` fails with `version solving failed` | Check for conflicting constraints; run `melos bootstrap --verbose` |
| Generated files out of date | `melos run gen:clean` |
| Package not found in IDE | Re-run `melos bootstrap` (symlinks reset) |
| CI fails but local works | Pin Flutter and Dart versions exactly (`sdkPath: auto` uses PATH) |
| `melos version` creates no tags | Ensure `git config user.email` is set in CI |

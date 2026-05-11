---
name: flutter-ci-cd
description: >
  Lead authority for Flutter CI/CD pipelines. Use when setting up GitHub Actions,
  Melos scripts, Fastlane automations, coverage gates, build flavors, obfuscation,
  golden test CI, Patrol CI, or store deployment pipelines.
---

# Flutter CI/CD Skill

## Purpose

Design and implement production-grade CI/CD pipelines for Flutter — from static analysis
to automated store deployment — with reproducible builds, quality gates, and fast feedback.

## Scope and authority

Lead authority for:

- GitHub Actions pipeline design (Flutter-specific)
- Melos workspace scripts and lifecycle hooks
- Fastlane integration (iOS/Android)
- Build flavor configuration (dev/staging/prod)
- obfuscation and symbol upload automation
- coverage gates and reporting (lcov)
- golden test execution in CI
- Patrol E2E in CI (emulator/Firebase Test Lab)
- Firebase App Distribution for internal testing
- store submission automation

---

## Standard pipeline stages

```yaml
# .github/workflows/ci.yml
name: Flutter CI

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main]

jobs:
  quality:
    name: Quality Gates
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.x'  # Pin to exact version
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Verify formatting
        run: dart format --check .

      - name: Analyze
        run: flutter analyze --fatal-infos

      - name: Run DCM (if configured)
        run: dart run dart_code_metrics:metrics analyze lib

      - name: Run tests with coverage
        run: flutter test --coverage --reporter=github

      - name: Check coverage threshold
        uses: VeryGoodOpenSource/very_good_coverage@v2
        with:
          path: coverage/lcov.info
          min_coverage: 80

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          file: coverage/lcov.info

  golden_tests:
    name: Golden Tests
    runs-on: ubuntu-latest  # Linux for deterministic font rendering
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.x'
          cache: true
      - run: flutter pub get
      - name: Run golden tests
        run: flutter test --tags golden

  build_android:
    name: Build Android (Release)
    runs-on: ubuntu-latest
    needs: quality
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.x'
          cache: true
      - uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Build release APK
        run: |
          flutter build apk --release \
            --obfuscate \
            --split-debug-info=build/symbols/ \
            --dart-define=ENV=production

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk

      - name: Upload symbols
        uses: actions/upload-artifact@v4
        with:
          name: debug-symbols
          path: build/symbols/

  build_ios:
    name: Build iOS (Release)
    runs-on: macos-latest
    needs: quality
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.x'
          cache: true

      - name: Build iOS (no code signing in CI)
        run: |
          flutter build ios --release \
            --no-codesign \
            --obfuscate \
            --split-debug-info=build/symbols/

  size_check:
    name: APK Size Check
    runs-on: ubuntu-latest
    needs: build_android
    steps:
      - name: Download APK
        uses: actions/download-artifact@v4
        with:
          name: release-apk

      - name: Check APK size regression
        run: |
          SIZE=$(stat -c%s app-release.apk)
          BASELINE=25000000  # 25MB — adjust to your app
          if [ $SIZE -gt $((BASELINE * 105 / 100)) ]; then
            echo "APK size regression: $SIZE bytes (>5% above baseline $BASELINE)"
            exit 1
          fi
```

---

## Melos workspace configuration

```yaml
# melos.yaml (monorepo root)
name: my_app_workspace

packages:
  - apps/**
  - packages/**

scripts:
  analyze:
    run: dart analyze
    exec:
      concurrency: 5
    description: Run static analysis on all packages

  test:
    run: flutter test --coverage
    exec:
      concurrency: 3
    description: Run all tests

  test:unit:
    run: flutter test test/unit
    exec:
      concurrency: 3

  test:widget:
    run: flutter test test/widget
    exec:
      concurrency: 2

  test:golden:
    run: flutter test --tags golden
    exec:
      concurrency: 1  # Golden tests need serial execution

  format:
    run: dart format .
    exec:
      concurrency: 5

  format:check:
    run: dart format --check .
    exec:
      concurrency: 5

  build:android:dev:
    run: >
      flutter build apk --debug
      --dart-define=ENV=development

  build:android:release:
    run: >
      flutter build apk --release
      --obfuscate
      --split-debug-info=build/symbols/
      --dart-define=ENV=production

  gen:
    run: dart run build_runner build --delete-conflicting-outputs
    exec:
      concurrency: 1
    description: Run code generation (Riverpod, Drift, Freezed)

  clean:
    run: flutter clean
    exec:
      concurrency: 3
```

---

## Build flavor configuration

### pubspec.yaml dart-define approach

```dart
// lib/config/env.dart
enum Environment { dev, staging, prod }

final class AppConfig {
  static const _env = String.fromEnvironment('ENV', defaultValue: 'dev');

  static Environment get environment => switch (_env) {
    'staging' => Environment.staging,
    'production' => Environment.prod,
    _ => Environment.dev,
  };

  static String get apiBaseUrl => switch (environment) {
    Environment.dev => 'https://dev-api.example.com',
    Environment.staging => 'https://staging-api.example.com',
    Environment.prod => 'https://api.example.com',
  };

  static bool get isProduction => environment == Environment.prod;
}
```

### Entry points per environment

```dart
// lib/main_dev.dart
void main() => _run(environment: 'development');

// lib/main_staging.dart
void main() => _run(environment: 'staging');

// lib/main.dart (production)
void main() => _run(environment: 'production');
```

---

## Fastlane integration

```ruby
# fastlane/Fastfile

lane :distribute_android do
  gradle(
    task: "bundle",
    build_type: "Release",
    properties: {
      "android.injected.signing.store.file" => ENV["KEYSTORE_PATH"],
      "android.injected.signing.store.password" => ENV["KEYSTORE_PASSWORD"],
      "android.injected.signing.key.alias" => ENV["KEY_ALIAS"],
      "android.injected.signing.key.password" => ENV["KEY_PASSWORD"],
    }
  )
  firebase_app_distribution(
    app: ENV["FIREBASE_APP_ID_ANDROID"],
    groups: "internal-testers",
    release_notes: changelog_from_git_commits(commits_count: 10)
  )
end

lane :distribute_ios do
  build_ios_app(
    scheme: "Runner",
    export_method: "ad-hoc",
    export_options: {
      signingStyle: "manual",
      provisioningProfiles: {
        "com.example.app" => "AdHoc Profile"
      }
    }
  )
  firebase_app_distribution(
    app: ENV["FIREBASE_APP_ID_IOS"],
    groups: "internal-testers"
  )
end
```

---

## Patrol CI (E2E on emulator)

```yaml
# In CI workflow — runs on merge to main only
e2e_tests:
  name: E2E Tests (Patrol)
  runs-on: macos-latest
  if: github.ref == 'refs/heads/main'
  steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
    - uses: reactivecircus/android-emulator-runner@v2
      with:
        api-level: 33
        script: flutter test integration_test --dart-define=ENV=test
```

---

## Release checklist automation

```yaml
# .github/workflows/release.yml
name: Release Validation

on:
  push:
    tags:
      - 'v*'

jobs:
  validate_release:
    steps:
      - name: Verify obfuscation flags
        run: |
          grep -r "obfuscate" fastlane/Fastfile || \
            (echo "Missing --obfuscate in release build!" && exit 1)

      - name: Check for debug flags in production code
        run: |
          grep -rn "kDebugMode\|debugPrint\|print(" lib/ \
            --include="*.dart" \
            | grep -v "_test.dart" \
            | grep -v "//.*print" \
            && echo "WARNING: debug statements in production code" || true
```

---

## Anti-pattern detection

- Flutter version not pinned in CI (use exact version, not `latest`)
- No coverage gate (coverage silently drops)
- Golden tests running on macOS (font rendering differs from Linux)
- Secrets hardcoded in workflow files (use GitHub Actions secrets)
- Build artifacts not versioned or tagged
- No APK size regression check
- Release builds without `--obfuscate` flag
- iOS builds without code signing validation step
- No separate workflow for release vs PR builds (slow feedback)

---

## Uncertainty protocol

- `High` (≥ 0.80): CI platform and project structure clear
- `Medium` (0.60–0.79): unclear mono vs multi-repo, or platform targets
- `Low` (< 0.60): no existing CI setup to build on

---

## Cross-skill handoff payload

Use the standard payload from `../../AGENTS.md`.
Set `requesting_skill` to `flutter-ci-cd`.

---

## Output contract

Follow global section order from `../../AGENTS.md`. Also include:

- `Pipeline stage diagram`
- `GitHub Actions workflow (complete)`
- `Melos scripts configuration`
- `Quality gate thresholds`
- `Release automation plan`

---

## Related resources

- `references/github-actions-guide.md`
- `references/melos-guide.md`
- `references/fastlane-guide.md`
- `references/patrol-ci-guide.md`
- `templates/ci-workflow.yml`
- `templates/melos.yaml`
- `templates/fastfile.rb`

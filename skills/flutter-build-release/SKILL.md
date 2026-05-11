---
name: flutter-build-release
description: >
  Lead authority for Flutter build and release engineering. Use for go/no-go decisions,
  build flavor configuration, signing, obfuscation, store submission, rollback planning,
  or defining release gates for production deployments.
---

# Flutter Build & Release Skill

## Purpose

Define and enforce production release standards — build integrity, signing, obfuscation,
store submission, staged rollout, and rollback strategy.

## Scope and authority

This skill has **production gate authority** for:

- go/no-go decisions for production releases
- release build configuration and signing
- obfuscation and symbol management
- store submission (Play Store, App Store)
- staged rollout and release monitoring
- rollback triggers and procedures
- release checklist enforcement

Defers to:

- `flutter-security` for security gate violations (may force go/no-go block)
- `flutter-testing` for test coverage gate status
- `flutter-ci-cd` for build pipeline correctness

---

## Go/No-Go checklist (mandatory before any production release)

### Security gates (all must pass)
```
□ --obfuscate flag applied to release build
□ --split-debug-info symbols uploaded to crash reporting
□ No API keys or secrets in source code (CI secret check passed)
□ flutter_secure_storage used for all tokens/PII
□ HTTPS enforced (no cleartext traffic allowed)
□ SSL pinning implemented (if financial/health app)
□ Debug logging disabled in release
```

### Quality gates
```
□ All unit tests passing (zero failures)
□ All widget tests passing (zero failures)
□ Golden tests passing (no unexpected diffs)
□ Coverage ≥ minimum threshold (configured in CI)
□ dart analyze returns zero errors/warnings
□ DCM metrics within configured thresholds
□ Critical user journeys covered by E2E (Patrol)
```

### Performance gates
```
□ Cold startup < 2s on P50 device (last measured)
□ No jank regression vs previous release (DevTools baseline)
□ APK/IPA size regression < 5% vs previous release
□ Memory RSS regression < 10% vs previous release
```

### Operational gates
```
□ Crashlytics configured and receiving events
□ Rollback procedure documented and tested
□ Staged rollout plan defined (% release schedule)
□ Monitoring alerts configured (crash rate threshold)
□ App version code incremented
□ Changelog updated
□ Store listing updated (screenshots, description)
```

---

## Build flavor configuration

### Recommended structure

```
lib/
  main.dart           # Production entry point
  main_dev.dart       # Development entry point
  main_staging.dart   # Staging entry point
```

### Android flavor configuration

```groovy
// android/app/build.gradle
android {
    flavorDimensions "environment"

    productFlavors {
        dev {
            dimension "environment"
            applicationIdSuffix ".dev"
            resValue "string", "app_name", "MyApp Dev"
            buildConfigField "String", "API_URL", '"https://dev-api.example.com"'
        }
        staging {
            dimension "environment"
            applicationIdSuffix ".staging"
            resValue "string", "app_name", "MyApp Staging"
            buildConfigField "String", "API_URL", '"https://staging-api.example.com"'
        }
        prod {
            dimension "environment"
            resValue "string", "app_name", "MyApp"
            buildConfigField "String", "API_URL", '"https://api.example.com"'
        }
    }
}
```

### Build commands per environment

```bash
# Development (debug, fast build, no obfuscation)
flutter run -t lib/main_dev.dart --flavor dev

# Staging (release build, testing-ready)
flutter build apk --release \
  -t lib/main_staging.dart \
  --flavor staging \
  --obfuscate \
  --split-debug-info=build/symbols/

# Production (full release)
flutter build appbundle --release \
  -t lib/main.dart \
  --flavor prod \
  --obfuscate \
  --split-debug-info=build/symbols/ \
  --dart-define=SENTRY_DSN=${{ secrets.SENTRY_DSN }}
```

---

## Signing configuration

### Android (keystore)

```groovy
// android/app/build.gradle
android {
    signingConfigs {
        release {
            storeFile file(System.getenv("KEYSTORE_PATH") ?: "keystore.jks")
            storePassword System.getenv("KEYSTORE_PASSWORD")
            keyAlias System.getenv("KEY_ALIAS")
            keyPassword System.getenv("KEY_PASSWORD")
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

**Never**: commit keystore files or passwords to source control.
**Always**: inject via CI secrets.

### iOS (certificates and profiles)

- Use `match` (Fastlane) for certificate management
- Store certificates in private git repo or App Store Connect API
- Use CI environment variables for passwords

---

## Symbol management

```bash
# After release build, upload symbols to Crashlytics
dart pub global activate flutterfire_cli

# Firebase Crashlytics symbol upload
firebase crashlytics:symbols:upload \
  --app=$FIREBASE_APP_ID \
  build/symbols/

# Sentry symbol upload (alternative)
sentry-cli upload-dif \
  --org=$SENTRY_ORG \
  --project=$SENTRY_PROJECT \
  build/symbols/
```

---

## Staged rollout strategy

| Stage | Rollout % | Monitoring duration | Rollback trigger |
|---|---|---|---|
| Internal | 100% (internal testers) | 24h | Any critical crash |
| Canary | 5% | 48h | Crash rate > 0.5% OR ANR rate > 0.1% |
| Staged | 20% → 50% → 100% | 24h per step | Crash rate > 1% |
| Full rollout | 100% | Ongoing | Crash rate > 2% |

---

## Rollback procedure

### Android (Play Store)
1. Navigate to Play Console → Release → Production
2. "Rollback to previous release" (available within 48h of rollout)
3. OR halt current rollout immediately (stops new installs)
4. Post-mortem: fix in hotfix branch → expedited review

### iOS (App Store)
1. No automatic rollback in App Store
2. Halt release if caught in review: reject the build
3. Submit expedited review for critical hotfix (document steps)
4. Mitigation: use Remote Config / feature flags to disable broken feature

---

## Version management

```yaml
# pubspec.yaml
version: 1.2.3+45
# format: MAJOR.MINOR.PATCH+BUILD_NUMBER
# Build number must always increment (never decrease)
```

### Automated version bumping

```bash
# Using CI environment (recommended)
VERSION_NAME="1.2.3"
BUILD_NUMBER=$GITHUB_RUN_NUMBER  # Always increasing in CI

flutter build appbundle \
  --build-name=$VERSION_NAME \
  --build-number=$BUILD_NUMBER \
  --release ...
```

---

## App size optimization

```bash
# Analyze size with Flutter size analysis
flutter build apk --analyze-size --target-platform android-arm64

# Output size breakdown to JSON
flutter build apk --analyze-size \
  --code-size-directory=build/code-size-output
```

### Deferred loading (Dart deferred imports)

```dart
// Defer loading heavy feature libraries
import 'features/heavy_editor/heavy_editor.dart' deferred as heavyEditor;

Future<void> openEditor() async {
  await heavyEditor.loadLibrary();
  heavyEditor.openEditor();
}
```

---

## Anti-pattern detection

- Release build without `--obfuscate` flag
- Keystore committed to source control
- No staged rollout (100% rollout immediately)
- No rollback procedure documented
- Debug mode features not disabled in release (`kDebugMode` checks missing)
- Version code not incrementing (causes rejected Play Store submission)
- No symbol upload (unreadable production crash stacks)
- Store screenshots not updated when UI changes significantly
- No release notes in changelog

---

## Uncertainty protocol

- `High` (≥ 0.80): all gates have current measurement data
- `Medium` (0.60–0.79): some gates lack recent measurement
- `Low` (< 0.60): missing baseline metrics for critical gates

If gates are unmeasured → return measurement-first plan before issuing go/no-go.

---

## Cross-skill handoff payload

Use the standard payload from `../../AGENTS.md`.
Set `requesting_skill` to `flutter-build-release`.

---

## Output contract

Follow global section order from `../../AGENTS.md`. Also include:

- `Go/No-Go assessment with gate statuses`
- `Build configuration`
- `Rollout plan`
- `Rollback procedure`
- `Post-release monitoring plan`

---

## Related resources

- `references/release-checklist.md`
- `references/signing-guide.md`
- `references/play-store-submission.md`
- `references/app-store-submission.md`
- `templates/release-checklist.md`
- `templates/build-scripts.sh`

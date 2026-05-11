# Release Hardening Checklist

Run this checklist for **every** production release. All Critical items are release blockers.

---

## Build flags

| Item | Required | Status |
|---|---|---|
| `--obfuscate` flag in release build | Critical | ☐ |
| `--split-debug-info=<dir>` flag | Critical | ☐ |
| Debug symbols uploaded to Crashlytics/Sentry | Critical | ☐ |
| `kReleaseMode` assertions verified | High | ☐ |

```bash
# Verify obfuscation applied — APK should contain no readable class names
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/symbols/

# Verify symbols exist after build
ls build/symbols/
```

---

## Secret and key management

| Item | Required | Status |
|---|---|---|
| No API keys in source code (grep check) | Critical | ☐ |
| No secrets in `pubspec.yaml` or asset files | Critical | ☐ |
| No secrets in git history | Critical | ☐ |
| CI injects secrets via environment variables | Critical | ☐ |
| Prod keys not present in dev flavor | High | ☐ |

```bash
# Automated grep check in CI
grep -rn "sk_live\|pk_live\|AIza\|api_key\|secret" \
  lib/ assets/ pubspec.yaml \
  --include="*.dart" --include="*.yaml" --include="*.json"
```

---

## Sensitive data storage

| Item | Required | Status |
|---|---|---|
| All tokens in `flutter_secure_storage` | Critical | ☐ |
| No sensitive data in `SharedPreferences` | Critical | ☐ |
| Database encrypted (if storing PII/regulated) | Critical | ☐ |
| `storage.deleteAll()` on logout | High | ☐ |

---

## Network security

| Item | Required | Status |
|---|---|---|
| `android:usesCleartextTraffic="false"` in release manifest | Critical | ☐ |
| iOS App Transport Security enabled (no `NSAllowsArbitraryLoads`) | Critical | ☐ |
| SSL pinning implemented (finance/health apps) | Context | ☐ |
| HTTPS enforced for all API endpoints | Critical | ☐ |

---

## Binary protection

| Item | Required | Status |
|---|---|---|
| ProGuard/R8 enabled for Android release | High | ☐ |
| `android:debuggable="false"` in release (auto via Flutter) | Critical | ☐ |
| `android:allowBackup="false"` for sensitive apps | High | ☐ |
| Root/jailbreak detection (finance/health) | Context | ☐ |

---

## Logging and debugging

| Item | Required | Status |
|---|---|---|
| All `print()` statements removed from production paths | High | ☐ |
| Debug logging interceptor disabled in release | Critical | ☐ |
| No sensitive data in log statements | Critical | ☐ |
| Crashlytics collection enabled for release only | High | ☐ |

```bash
# Check for leftover print statements
grep -rn "^[^/]*print(" lib/ --include="*.dart" | grep -v "_test.dart"
```

---

## Build integrity

| Item | Required | Status |
|---|---|---|
| Version code incremented from previous release | Critical | ☐ |
| Release signed with correct keystore (not debug keystore) | Critical | ☐ |
| Build reproducible from clean checkout | High | ☐ |
| `flutter clean` + fresh `pub get` before release build | High | ☐ |

---

## Post-build verification

```bash
# Verify no debug symbols in APK (should be empty/obfuscated class names)
apkanalyzer dex packages app-release.apk | head -20

# Verify APK signed correctly
apksigner verify --verbose app-release.apk

# Check APK size regression
stat -c%s app-release.apk
```

---

## Sign-off

| Reviewer | Role | Date | Signature |
|---|---|---|---|
| | Security | | |
| | Lead Engineer | | |
| | QA | | |

---
name: flutter-security
description: >
  Global critical override authority for Flutter security. Use whenever credentials,
  tokens, PII, secure storage, SSL pinning, obfuscation, root detection, or
  sensitive data handling is in scope. Can override convenience, performance, and UX.
---

# Flutter Security Skill

## Purpose

Provide threat-aware Flutter security recommendations that reduce exploitability risk
while remaining operationally feasible. Security is never optional — it is a release gate.

## Scope and authority

This skill has **global critical override authority** for:

- exploitable security risk in any layer
- sensitive data exposure pathways (tokens, PII, credentials)
- secrets and trust-boundary handling
- network transport security
- binary protection and release hardening

If security risk is **Critical**, this skill overrides convenience, performance, and UX preferences.

---

## When to use

- Designing or reviewing authentication/token lifecycle
- Choosing storage solutions for sensitive data
- Implementing SSL pinning or certificate validation
- Planning obfuscation and release hardening
- Assessing security posture of architecture/build changes
- Root/jailbreak detection requirements
- Logging strategy review (PII leakage risk)

---

## Decision engine workflow

1. Identify assets (tokens, PII, keys, payment data) and trust boundaries.
2. Classify attacker capabilities (physical device, network, app store repackaging).
3. Rank threats by exploitability and business impact.
4. Choose mitigations by risk reduction vs operational cost.
5. Define rollout controls, monitoring, and residual risk.
6. Align with release constraints and incident response readiness.

---

## Branching decision tree

### Branch A: risk classification

- **Critical exploitability** (credentials, PII, payment data exposed):
  - Block release if unresolved
  - Enforce immediate mitigation path
  - Escalate to `flutter-build-release`

- **High but non-blocking** (hardening improvements, defense-in-depth):
  - Prioritize near-term remediation
  - Add as release gate for next version

- **Medium/Low** (informational improvements):
  - Schedule hardening with explicit risk acceptance notes
  - Document residual risk

### Branch B: storage security

```
Sensitive data (tokens, credentials, PII, biometric keys)
→ ALWAYS: flutter_secure_storage (Keychain on iOS, Keystore on Android)
→ NEVER: SharedPreferences, Hive unencrypted, plain sqlite

Semi-sensitive data (user preferences, non-critical settings)
→ OK: SharedPreferences or Hive CE

Highly regulated data (financial, health records)
→ ALWAYS: Drift + SQLCipher (encrypted SQLite)
```

### Branch C: network security

- **All apps**: HTTPS enforced, no cleartext traffic
  - Android: `android:usesCleartextTraffic="false"` in manifest
  - iOS: App Transport Security (ATS) enabled
  
- **Financial/health/enterprise apps**: Certificate pinning required
  - Implement via custom `SecurityContext` in Dio
  - Pin leaf certificate + intermediate + rotate backup pins
  - Have pin rotation procedure documented before shipping

- **Sensitive API endpoints**: Request signing (HMAC) where possible

### Branch D: release hardening (mandatory for all production builds)

```bash
# Required flags for every release build:
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/symbols/

flutter build ios --release \
  --obfuscate \
  --split-debug-info=build/symbols/
```

- Upload symbols to Crashlytics/Sentry for deobfuscated crash reports
- Never commit `--split-debug-info` output to source control
- API keys: CI secret injection only (GitHub Actions secrets, Fastlane env)
- Build flavors: no production keys in development builds

---

## Quantitative gates

Label each `pass | at-risk | fail`:

| Gate | Requirement | Release impact |
|---|---|---|
| Sensitive data in secure storage | All tokens/PII in flutter_secure_storage | Release blocker if fail |
| API keys in source | Zero hardcoded keys in source/assets | Release blocker if fail |
| HTTPS enforcement | No cleartext traffic in release builds | Release blocker if fail |
| Obfuscation applied | `--obfuscate` flag in release build | Release blocker if fail |
| SSL pinning (high-security apps) | Pinning implemented with rotation plan | Required for finance/health |
| Debug logging disabled | No sensitive data in release logs | Required |
| Root detection (high-security) | Implemented with appropriate fallback | Context-dependent |

---

## Sensitive data handling rules

### Authentication tokens
```dart
// ✅ Store in secure storage
const storage = FlutterSecureStorage();
await storage.write(key: 'access_token', value: token);

// ❌ NEVER store in SharedPreferences
final prefs = await SharedPreferences.getInstance();
prefs.setString('access_token', token); // PROHIBITED
```

### Token lifecycle
- Access tokens: in-memory only (Riverpod state) + secure storage for persistence
- Refresh tokens: flutter_secure_storage only
- On logout: explicitly delete from secure storage (`storage.deleteAll()`)
- Token expiry: handle transparently via Dio auth interceptor

### Logging rules
```dart
// ✅ Safe — no sensitive data
logger.info('User authenticated', {'userId': user.id});

// ❌ PROHIBITED — token in logs
logger.debug('Token: $accessToken');

// ❌ PROHIBITED — PII in logs
logger.info('User email: ${user.email}');
```

---

## Platform-specific security controls

### Android
- `android:debuggable="false"` in release manifest (enforced by Flutter release build)
- `android:allowBackup="false"` to prevent ADB backup of sensitive data
- ProGuard/R8 rules for native library protection
- Play Integrity API for app attestation (high-security apps)

### iOS
- App Transport Security: no NSAllowsArbitraryLoads exceptions
- Keychain Access Groups for secure token sharing between extensions
- Jailbreak detection for financial apps: `flutter_jailbreak_detection`

---

## Tradeoff realism

- Interim controls are acceptable if expiry criteria are defined
- Partial hardening is acceptable near release windows when residual risk is transparent
- Do NOT frame risk acceptance as risk elimination
- Certificate pinning has operational cost (pin rotation) — document before implementing

---

## Anti-pattern detection

- Tokens or PII in SharedPreferences → Critical
- API keys in source code or pubspec.yaml → Critical
- `android:debuggable="true"` in release build → Critical
- Cleartext HTTP traffic in production → Critical
- `--obfuscate` missing from release build → High
- Debug logging enabled in release builds → High
- Custom crypto without expert review → High
- `print()` statements with sensitive data → High
- UI-only security checks without server enforcement → Medium
- Biometric authentication bypassed via software → Critical

---

## Uncertainty protocol

- `High` (≥ 0.80): threat surface clear, assets identified
- `Medium` (0.60–0.79): incomplete threat model
- `Low` (< 0.60): missing app context, platform targets, or data classification

If Medium/Low: request threat model completion before finalizing controls.

---

## Cross-skill handoff payload

Use the standard payload from `../../AGENTS.md`.
Set `requesting_skill` to `flutter-security`.

---

## Output contract

Follow global section order from `../../AGENTS.md`. Also include:

- `Risk summary`
- `Asset and threat surface map`
- `Mitigation plan by risk class`
- `Storage/network/binary controls`
- `Residual risks and acceptance criteria`
- `Implementation priorities`

---

## Related resources

- `references/mobile-threat-model.md`
- `references/secure-storage-guide.md`
- `references/ssl-pinning-guide.md`
- `references/release-hardening-checklist.md`
- `templates/security-review.md`

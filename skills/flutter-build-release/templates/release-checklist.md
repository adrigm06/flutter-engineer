# Release Checklist

> **App**: [App name]
> **Version**: X.Y.Z+BUILD
> **Release manager**: [Name]
> **Target**: ☐ Play Store | ☐ App Store | ☐ Both
> **Date**: YYYY-MM-DD

---

## Phase 1 — Quality gates (CI must pass)

| Gate | Status | Notes |
|---|---|---|
| All unit tests pass (0 failures) | ☐ | |
| All widget tests pass (0 failures) | ☐ | |
| Golden tests pass (no unexpected diffs) | ☐ | |
| Coverage ≥ threshold | ☐ | Current: __% |
| `dart analyze` zero errors/warnings | ☐ | |
| Critical journeys E2E green (Patrol) | ☐ | |

---

## Phase 2 — Security gates

| Gate | Status | Notes |
|---|---|---|
| `--obfuscate` flag in release build | ☐ | |
| `--split-debug-info` artifacts generated | ☐ | |
| Debug symbols uploaded to Crashlytics/Sentry | ☐ | |
| Zero API keys in source (CI grep passed) | ☐ | |
| Tokens stored in flutter_secure_storage (not SharedPrefs) | ☐ | |
| HTTPS enforced (no cleartext traffic) | ☐ | |
| Logging interceptor disabled in release | ☐ | |
| No `print()` statements in production paths | ☐ | |

---

## Phase 3 — Performance gates

| Gate | Threshold | Current | Status |
|---|---|---|---|
| Cold startup | < 2s (P50 mid-range Android) | | ☐ |
| APK size | < 5% regression vs previous | | ☐ |
| Memory RSS | < 10% regression vs baseline | | ☐ |
| No jank regression (DevTools timeline) | | | ☐ |

---

## Phase 4 — Build configuration

| Item | Status |
|---|---|
| Version code incremented (never decreases) | ☐ |
| Version name updated (semver) | ☐ |
| Release flavor uses production API URL | ☐ |
| No development/staging config in prod build | ☐ |
| Build signed with release keystore (not debug) | ☐ |
| `flutter clean` + fresh `pub get` before final build | ☐ |

---

## Phase 5 — Observability

| Item | Status |
|---|---|
| Crashlytics enabled and collecting in production | ☐ |
| Performance monitoring configured | ☐ |
| Alert thresholds configured (crash rate > X%) | ☐ |
| Staged rollout plan defined | ☐ |
| Rollback procedure documented and accessible | ☐ |

---

## Phase 6 — Store submission

| Item | Status |
|---|---|
| Changelog / release notes written | ☐ |
| Store listing updated (screenshots if UI changed) | ☐ |
| Privacy policy updated (if data collection changed) | ☐ |
| App review guidelines compliance checked | ☐ |
| Staged rollout % defined (5% → 20% → 50% → 100%) | ☐ |

---

## Staged rollout schedule

| Stage | % | Start date | Monitoring period | Rollback trigger |
|---|---|---|---|---|
| Internal | 100% (internal) | | 24h | Any critical crash |
| Canary | 5% | | 48h | Crash rate > 0.5% |
| Partial | 20% | | 24h | Crash rate > 1% |
| Wide | 50% | | 24h | Crash rate > 1% |
| Full | 100% | | Ongoing | Crash rate > 2% |

---

## Post-release monitoring

Monitor for 48h after reaching 50% rollout:

- [ ] Crash-free rate ≥ 99.5%
- [ ] ANR rate ≤ 0.1%
- [ ] No critical bugs in reviews/support
- [ ] Core business metrics stable

---

## Sign-off

| Reviewer | Role | Signature | Date |
|---|---|---|---|
| | QA | | |
| | Security | | |
| | Lead Engineer | | |
| | Product | | |

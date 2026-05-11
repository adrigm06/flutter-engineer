# Security Review Report

> **App / Feature**: [Name]
> **Reviewer**: [Name]
> **Date**: YYYY-MM-DD
> **Review type**: Full security audit | Feature review | Release gate check

---

## Threat model summary

| Asset | Classification | Attack surface |
|---|---|---|
| Auth tokens | Critical | Storage, memory, logs, network |
| User PII (name, email) | High | Storage, logs, analytics |
| Payment data | Critical | Network, storage |
| API keys | Critical | Binary, source code, logs |
| App logic | Medium | Reverse engineering |

---

## Finding summary

| Severity | Count |
|---|---|
| 🔴 Critical | 0 |
| 🟠 High | 0 |
| 🟡 Medium | 0 |
| 🔵 Low | 0 |

---

## Findings

### 🔴 CRITICAL

#### Finding [C-001]: [Title]

- **Location**: `lib/features/auth/data/auth_local_data_source.dart:42`
- **Description**: Access token stored in SharedPreferences instead of flutter_secure_storage.
- **Exploitability**: Any app with `READ_EXTERNAL_STORAGE` or ADB backup can extract the token.
- **CWE**: CWE-312 Cleartext Storage of Sensitive Information
- **Fix**:
  ```dart
  // ❌ Current
  await prefs.setString('access_token', token);
  
  // ✅ Required
  await _secureStorage.write(key: 'access_token', value: token);
  ```
- **Release impact**: ☐ Block release | ☐ Fix by [date]

---

### 🟠 HIGH

#### Finding [H-001]: [Title]

- **Location**: `lib/core/network/logging_interceptor.dart:18`
- **Description**: Authorization header logged at WARNING level (visible in release builds).
- **Fix**: Remove all header logging. Use `assert()` to restrict to debug builds only.
- **Release impact**: ☐ Fix before release | ☐ Fix by next sprint

---

### 🟡 MEDIUM

_Medium findings documented here._

---

### 🔵 LOW

_Low findings documented here._

---

## Hardening checklist status

| Control | Status | Notes |
|---|---|---|
| `--obfuscate` in release build | ✅ Pass | Verified in CI |
| Secrets via CI injection | ✅ Pass | No hardcoded keys |
| Tokens in secure storage | ❌ Fail | See C-001 |
| HTTPS enforced | ✅ Pass | Cleartext disabled |
| Logging safe in release | ⚠️ At-risk | See H-001 |
| SSL pinning | N/A | Non-financial app |

---

## Residual risks (accepted)

| Risk | Justification | Expiry |
|---|---|---|
| No root detection | Low-security app, no financial data | Revisit if payment added |

---

## Recommended remediation order

1. **C-001** — Token storage (block release)
2. **H-001** — Auth header logging (fix before next release)
3. **M-001** — ... (fix this sprint)

---

## Sign-off

| Item | Status |
|---|---|
| All Critical findings resolved | ☐ |
| High findings resolved or accepted with date | ☐ |
| Hardening checklist complete | ☐ |
| Approved for release | ☐ |

**Security reviewer**: _____________________________ Date: ____________
